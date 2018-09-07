#import "OngoingCallThreadLocalContext.h"

#import "../../libtgvoip/VoIPController.h"
#import "../../libtgvoip/os/darwin/SetupLogging.h"

#import <MtProtoKitDynamic/MtProtoKitDynamic.h>

static void TGCallAesIgeEncrypt(uint8_t *inBytes, uint8_t *outBytes, size_t length, uint8_t *key, uint8_t *iv) {
    MTAesEncryptRaw(inBytes, outBytes, length, key, iv);
}

static void TGCallAesIgeDecrypt(uint8_t *inBytes, uint8_t *outBytes, size_t length, uint8_t *key, uint8_t *iv) {
    MTAesDecryptRaw(inBytes, outBytes, length, key, iv);
}

static void TGCallSha1(uint8_t *msg, size_t length, uint8_t *output) {
    MTRawSha1(msg, length, output);
}

static void TGCallSha256(uint8_t *msg, size_t length, uint8_t *output) {
    MTRawSha256(msg, length, output);
}

static void TGCallAesCtrEncrypt(uint8_t *inOut, size_t length, uint8_t *key, uint8_t *iv, uint8_t *ecount, uint32_t *num) {
    uint8_t *outData = (uint8_t *)malloc(length);
    MTAesCtr *aesCtr = [[MTAesCtr alloc] initWithKey:key keyLength:32 iv:iv ecount:ecount num:*num];
    [aesCtr encryptIn:inOut out:outData len:length];
    memcpy(inOut, outData, length);
    free(outData);
    
    [aesCtr getIv:iv];
    
    memcpy(ecount, [aesCtr ecount], 16);
    *num = [aesCtr num];
}

static void TGCallRandomBytes(uint8_t *buffer, size_t length) {
    arc4random_buf(buffer, length);
}

@implementation OngoingCallConnectionDescription

- (instancetype _Nonnull)initWithConnectionId:(int64_t)connectionId ip:(NSString * _Nonnull)ip ipv6:(NSString * _Nonnull)ipv6 port:(int32_t)port peerTag:(NSData * _Nonnull)peerTag {
    self = [super init];
    if (self != nil) {
        _connectionId = connectionId;
        _ip = ip;
        _ipv6 = ipv6;
        _port = port;
        _peerTag = peerTag;
    }
    return self;
}

@end

static MTAtomic *callContexts() {
    static MTAtomic *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MTAtomic alloc] initWithValue:[[NSMutableDictionary alloc] init]];
    });
    return instance;
}

@interface OngoingCallThreadLocalContextReference : NSObject

@property (nonatomic, weak) OngoingCallThreadLocalContext *context;
@property (nonatomic, strong, readonly) id<OngoingCallThreadLocalContextQueue> queue;

@end

@implementation OngoingCallThreadLocalContextReference

- (instancetype)initWithContext:(OngoingCallThreadLocalContext *)context queue:(id<OngoingCallThreadLocalContextQueue>)queue {
    self = [super init];
    if (self != nil) {
        self.context = context;
        _queue = queue;
    }
    return self;
}

@end

static int32_t nextId = 1;

static int32_t addContext(OngoingCallThreadLocalContext *context, id<OngoingCallThreadLocalContextQueue> queue) {
    int32_t contextId = OSAtomicIncrement32(&nextId);
    [callContexts() with:^id(NSMutableDictionary *dict) {
        dict[@(contextId)] = [[OngoingCallThreadLocalContextReference alloc] initWithContext:context queue:queue];
        return nil;
    }];
    return contextId;
}

static void removeContext(int32_t contextId) {
    [callContexts() with:^id(NSMutableDictionary *dict) {
        [dict removeObjectForKey:@(contextId)];
        return nil;
    }];
}

static void withContext(int32_t contextId, void (^f)(OngoingCallThreadLocalContext *)) {
    __block OngoingCallThreadLocalContextReference *reference = nil;
    [callContexts() with:^id(NSMutableDictionary *dict) {
        reference = dict[@(contextId)];
        return nil;
    }];
    if (reference != nil) {
        [reference.queue dispatch:^{
            __strong OngoingCallThreadLocalContext *context = reference.context;
            if (context != nil) {
                f(context);
            }
        }];
    }
}

@interface OngoingCallThreadLocalContext () {
    id<OngoingCallThreadLocalContextQueue> _queue;
    int32_t _contextId;

    OngoingCallNetworkType _networkType;
    NSTimeInterval _callReceiveTimeout;
    NSTimeInterval _callRingTimeout;
    NSTimeInterval _callConnectTimeout;
    NSTimeInterval _callPacketTimeout;
    int32_t _dataSavingMode;
    bool _allowP2P;
    
    tgvoip::VoIPController *_controller;
    
    OngoingCallState _state;
}

- (void)controllerStateChanged:(int)state;

@end

static void controllerStateCallback(tgvoip::VoIPController *controller, int state) {
    int32_t contextId = (int32_t)((intptr_t)controller->implData);
    withContext(contextId, ^(OngoingCallThreadLocalContext *context) {
        [context controllerStateChanged:state];
    });
}

@implementation VoipProxyServer

- (instancetype _Nonnull)initWithHost:(NSString * _Nonnull)host port:(int32_t)port username:(NSString * _Nullable)username password:(NSString * _Nullable)password {
    self = [super init];
    if (self != nil) {
        _host = host;
        _port = port;
        _username = username;
        _password = password;
    }
    return self;
}

@end

static int callControllerNetworkTypeForType(OngoingCallNetworkType type) {
    switch (type) {
        case OngoingCallNetworkTypeWifi:
            return tgvoip::NET_TYPE_WIFI;
        case OngoingCallNetworkTypeCellularGprs:
            return tgvoip::NET_TYPE_GPRS;
        case OngoingCallNetworkTypeCellular3g:
            return tgvoip::NET_TYPE_3G;
        case OngoingCallNetworkTypeCellularLte:
            return tgvoip::NET_TYPE_LTE;
        default:
            return tgvoip::NET_TYPE_WIFI;
    }
}

@implementation OngoingCallThreadLocalContext

+ (void)setupLoggingFunction:(void (*)(NSString *))loggingFunction {
    TGVoipLoggingFunction = loggingFunction;
}

- (instancetype _Nonnull)initWithQueue:(id<OngoingCallThreadLocalContextQueue> _Nonnull)queue allowP2P:(BOOL)allowP2P proxy:(VoipProxyServer * _Nullable)proxy networkType:(OngoingCallNetworkType)networkType {
    self = [super init];
    if (self != nil) {
        _queue = queue;
        assert([queue isCurrent]);
        _contextId = addContext(self, queue);
        
        _callReceiveTimeout = 20.0;
        _callRingTimeout = 90.0;
        _callConnectTimeout = 30.0;
        _callPacketTimeout = 10.0;
        _dataSavingMode = 0;
        _allowP2P = allowP2P;
        _networkType = networkType;
        
        _controller = new tgvoip::VoIPController();
        _controller->implData = (void *)((intptr_t)_contextId);
        
        if (proxy != nil) {
            _controller->SetProxy(tgvoip::PROXY_SOCKS5, proxy.host.UTF8String, (uint16_t)proxy.port, proxy.username.UTF8String ?: "", proxy.password.UTF8String ?: "");
        }
        _controller->SetNetworkType(callControllerNetworkTypeForType(networkType));
        
        auto callbacks = tgvoip::VoIPController::Callbacks();
        callbacks.connectionStateChanged = &controllerStateCallback;
        callbacks.groupCallKeyReceived = NULL;
        callbacks.groupCallKeySent = NULL;
        callbacks.signalBarCountChanged = NULL;
        callbacks.upgradeToGroupCallRequested = NULL;
        _controller->SetCallbacks(callbacks);
        
        tgvoip::VoIPController::crypto.sha1 = &TGCallSha1;
        tgvoip::VoIPController::crypto.sha256 = &TGCallSha256;
        tgvoip::VoIPController::crypto.rand_bytes = &TGCallRandomBytes;
        tgvoip::VoIPController::crypto.aes_ige_encrypt = &TGCallAesIgeEncrypt;
        tgvoip::VoIPController::crypto.aes_ige_decrypt = &TGCallAesIgeDecrypt;
        tgvoip::VoIPController::crypto.aes_ctr_encrypt = &TGCallAesCtrEncrypt;
        
        _state = OngoingCallStateInitializing;
    }
    return self;
}

- (void)dealloc {
    assert([_queue isCurrent]);
    removeContext(_contextId);
    if (_controller != NULL) {
        [self stop];
    }
}

- (void)startWithKey:(NSData * _Nonnull)key isOutgoing:(bool)isOutgoing primaryConnection:(OngoingCallConnectionDescription * _Nonnull)primaryConnection alternativeConnections:(NSArray<OngoingCallConnectionDescription *> * _Nonnull)alternativeConnections maxLayer:(int32_t)maxLayer {
    std::vector<tgvoip::Endpoint> endpoints;
    NSArray<OngoingCallConnectionDescription *> *connections = [@[primaryConnection] arrayByAddingObjectsFromArray:alternativeConnections];
    for (OngoingCallConnectionDescription *connection in connections) {
        struct in_addr addrIpV4;
        if (!inet_aton(connection.ip.UTF8String, &addrIpV4)) {
            NSLog(@"CallSession: invalid ipv4 address");
        }
        
        struct in6_addr addrIpV6;
        if (!inet_pton(AF_INET6, connection.ipv6.UTF8String, &addrIpV6)) {
            NSLog(@"CallSession: invalid ipv6 address");
        }
        
        tgvoip::IPv4Address address(std::string(connection.ip.UTF8String));
        tgvoip::IPv6Address addressv6(std::string(connection.ipv6.UTF8String));
        unsigned char peerTag[16];
        [connection.peerTag getBytes:peerTag length:16];
        endpoints.push_back(tgvoip::Endpoint(connection.connectionId, (uint16_t)connection.port, address, addressv6, tgvoip::Endpoint::TYPE_UDP_RELAY, peerTag));
        /*releasable*/
        //endpoints.push_back(tgvoip::Endpoint(connection.connectionId, (uint16_t)connection.port, address, addressv6, EP_TYPE_UDP_RELAY, peerTag));
    }
    
    tgvoip::VoIPController::Config config(_callConnectTimeout, _callPacketTimeout, _dataSavingMode, false, true, true);
    config.logFilePath = "";
    config.statsDumpFilePath = "";
    
    _controller->SetConfig(config);
    
    _controller->SetEncryptionKey((char *)key.bytes, isOutgoing);
    /*releasable*/
    _controller->SetRemoteEndpoints(endpoints, _allowP2P, maxLayer);
    _controller->Start();
    
    _controller->Connect();
}

- (void)stop {
    if (_controller) {
        char *buffer = (char *)malloc(_controller->GetDebugLogLength());
        /*releasable*/
        _controller->Stop();
        _controller->GetDebugLog(buffer);
        NSString *debugLog = [[NSString alloc] initWithUTF8String:buffer];
        
        tgvoip::VoIPController::TrafficStats stats;
        _controller->GetStats(&stats);
        delete _controller;
        _controller = NULL;
    }
    
    /*MTNetworkUsageManager *usageManager = [[MTNetworkUsageManager alloc] initWithInfo:[[TGTelegramNetworking instance] mediaUsageInfoForType:TGNetworkMediaTypeTagCall]];
    [usageManager addIncomingBytes:stats.bytesRecvdMobile interface:MTNetworkUsageManagerInterfaceWWAN];
    [usageManager addIncomingBytes:stats.bytesRecvdWifi interface:MTNetworkUsageManagerInterfaceOther];
    
    [usageManager addOutgoingBytes:stats.bytesSentMobile interface:MTNetworkUsageManagerInterfaceWWAN];
    [usageManager addOutgoingBytes:stats.bytesSentWifi interface:MTNetworkUsageManagerInterfaceOther];*/
    
    //if (sendDebugLog && self.peerId != 0 && self.accessHash != 0)
    //    [[TGCallSignals saveCallDebug:self.peerId accessHash:self.accessHash data:debugLog] startWithNext:nil];
}

- (void)controllerStateChanged:(int)state {
    OngoingCallState callState = OngoingCallStateInitializing;
    /*releasable*/
    switch (state) {
        case tgvoip::STATE_ESTABLISHED:
            callState = OngoingCallStateConnected;
            break;
        case tgvoip::STATE_FAILED:
            callState = OngoingCallStateFailed;
            break;
        default:
            break;
    }
    /*switch (state) {
        case STATE_ESTABLISHED:
            callState = OngoingCallStateConnected;
            break;
        case STATE_FAILED:
            callState = OngoingCallStateFailed;
            break;
        default:
            break;
    }*/
    
    if (callState != _state) {
        _state = callState;
        
        if (_stateChanged) {
            _stateChanged(callState);
        }
    }
}

- (void)setIsMuted:(bool)isMuted {
    _controller->SetMicMute(isMuted);
}

- (void)setNetworkType:(OngoingCallNetworkType)networkType {
    if (_networkType != networkType) {
        _networkType = networkType;
        _controller->SetNetworkType(callControllerNetworkTypeForType(networkType));
    }
}

@end
