import Foundation
import Display
import TelegramCore
import Postbox
import SwiftSignalKit

final class ChatRecentActionsController: ViewController {
    private var controllerNode: ChatRecentActionsControllerNode {
        return self.displayNode as! ChatRecentActionsControllerNode
    }
    
    private let account: Account
    private let peer: Peer
    private var presentationData: PresentationData
    
    private var interaction: ChatRecentActionsInteraction!
    private var panelInteraction: ChatPanelInterfaceInteraction!
    
    private let titleView: ChatRecentActionsTitleView
    
    init(account: Account, peer: Peer) {
        self.account = account
        self.peer = peer
        
        self.presentationData = account.telegramApplicationContext.currentPresentationData.with { $0 }
        
        self.titleView = ChatRecentActionsTitleView(color: self.presentationData.theme.rootController.navigationBar.primaryTextColor)
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBar.style.style
        
        self.interaction = ChatRecentActionsInteraction(displayInfoAlert: { [weak self] in
            if let strongSelf = self {
                self?.present(standardTextAlertController(theme: AlertControllerTheme(presentationTheme: strongSelf.presentationData.theme), title: strongSelf.presentationData.strings.Channel_AdminLog_InfoPanelAlertTitle, text: strongSelf.presentationData.strings.Channel_AdminLog_InfoPanelAlertText, actions: [TextAlertAction(type: .defaultAction, title: strongSelf.presentationData.strings.Common_OK, action: {})]), in: .window(.root))
            }
        })
        
        self.panelInteraction = ChatPanelInterfaceInteraction(setupReplyMessage: { _ in
        }, setupEditMessage: { _ in
        }, beginMessageSelection: { _ in
        }, deleteSelectedMessages: {
        }, reportSelectedMessages: {
        }, reportMessages: { _ in
        }, deleteMessages: { _ in
        }, forwardSelectedMessages: {
        }, forwardMessages: { _ in
        }, shareSelectedMessages: {
        }, updateTextInputStateAndMode: { _ in
        }, updateInputModeAndDismissedButtonKeyboardMessageId: { _ in
        }, editMessage: {
        }, beginMessageSearch: { _, _ in
        }, dismissMessageSearch: {
        }, updateMessageSearch: { _ in
        }, navigateMessageSearch: { _ in
        }, openCalendarSearch: {
        }, toggleMembersSearch: { _ in
        }, navigateToMessage: { _ in
        }, openPeerInfo: {
        }, togglePeerNotifications: {
        }, sendContextResult: { _, _ in
        }, sendBotCommand: { _, _ in
        }, sendBotStart: { _ in
        }, botSwitchChatWithPayload: { _, _ in
        }, beginMediaRecording: { _ in
        }, finishMediaRecording: { _ in
        }, stopMediaRecording: {
        }, lockMediaRecording: {
        }, deleteRecordedMedia: {
        }, sendRecordedMedia: {
        }, displayRestrictedInfo: { _ in
        }, switchMediaRecordingMode: {
        }, setupMessageAutoremoveTimeout: {
        }, sendSticker: { _ in
        }, unblockPeer: {
        }, pinMessage: { _ in
        }, unpinMessage: {
        }, reportPeer: {
        }, dismissReportPeer: {
        }, deleteChat: {
        }, beginCall: {
        }, toggleMessageStickerStarred: { _ in
        }, presentController: { _, _ in
        }, presentGlobalOverlayController: { _, _ in
        }, navigateFeed: {
        }, openGrouping: {
        }, toggleSilentPost: {
        }, statuses: nil)
        
        self.navigationItem.titleView = self.titleView
        
        let rightButton = ChatNavigationButton(action: .search, buttonItem: UIBarButtonItem(image: PresentationResourcesRootController.navigationSearchIcon(self.presentationData.theme), style: .plain, target: self, action: #selector(self.activateSearch)))
        self.navigationItem.setRightBarButton(rightButton.buttonItem, animated: false)
        
        self.titleView.title = self.presentationData.strings.Channel_AdminLog_TitleAllEvents
        self.titleView.pressed = { [weak self] in
            self?.openFilterSetup()
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadDisplayNode() {
        self.displayNode = ChatRecentActionsControllerNode(account: self.account, peer: self.peer, presentationData: self.presentationData, interaction: self.interaction, pushController: { [weak self] c in
            (self?.navigationController as? NavigationController)?.pushViewController(c)
        }, presentController: { [weak self] c, a in
            self?.present(c, in: .window(.root), with: a)
        }, getNavigationController: { [weak self] in
            return self?.navigationController as? NavigationController
        })
        
        self.displayNodeDidLoad()
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        self.controllerNode.containerLayoutUpdated(layout, navigationBarHeight: self.navigationHeight, transition: transition)
    }
    
    @objc func activateSearch() {
        if let navigationBar = self.navigationBar {
            if !(navigationBar.contentNode is ChatRecentActionsSearchNavigationContentNode) {
                let searchNavigationNode = ChatRecentActionsSearchNavigationContentNode(theme: self.presentationData.theme, strings: self.presentationData.strings, cancel: { [weak self] in
                    self?.deactivateSearch()
                })
            
                navigationBar.setContentNode(searchNavigationNode, animated: true)
                searchNavigationNode.setQueryUpdated({ [weak self] query in
                    self?.controllerNode.updateSearchQuery(query)
                    self?.updateTitle()
                })
                searchNavigationNode.activate()
            }
        }
    }
    
    private func deactivateSearch() {
        self.controllerNode.updateSearchQuery("")
        self.navigationBar?.setContentNode(nil, animated: true)
        self.updateTitle()
    }
    
    private func openFilterSetup() {
        self.present(channelRecentActionsFilterController(account: self.account, peer: self.peer, events: self.controllerNode.filter.events, adminPeerIds: self.controllerNode.filter.adminPeerIds, apply: { [weak self] events, adminPeerIds in
            self?.controllerNode.updateFilter(events: events, adminPeerIds: adminPeerIds)
            self?.updateTitle()
        }), in: .window(.root), with: ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
    }
    
    private func updateTitle() {
        if self.controllerNode.filter.isEmpty {
            self.titleView.title = self.presentationData.strings.Channel_AdminLog_TitleAllEvents
        } else {
            self.titleView.title = self.presentationData.strings.Channel_AdminLog_TitleSelectedEvents
        }
    }
}
