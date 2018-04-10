
fileprivate let parsers: [Int32 : (BufferReader) -> Any?] = {
    var dict: [Int32 : (BufferReader) -> Any?] = [:]
    dict[-1471112230] = { return $0.readInt32() }
    dict[570911930] = { return $0.readInt64() }
    dict[571523412] = { return $0.readDouble() }
    dict[-1255641564] = { return parseString($0) }
    dict[-1240849242] = { return Api.messages.StickerSet.parse_stickerSet($0) }
    dict[-457104426] = { return Api.InputGeoPoint.parse_inputGeoPointEmpty($0) }
    dict[-206066487] = { return Api.InputGeoPoint.parse_inputGeoPoint($0) }
    dict[-784000893] = { return Api.payments.ValidatedRequestedInfo.parse_validatedRequestedInfo($0) }
    dict[771925524] = { return Api.ChatFull.parse_chatFull($0) }
    dict[1991201921] = { return Api.ChatFull.parse_channelFull($0) }
    dict[-925415106] = { return Api.ChatParticipant.parse_chatParticipant($0) }
    dict[-636267638] = { return Api.ChatParticipant.parse_chatParticipantCreator($0) }
    dict[-489233354] = { return Api.ChatParticipant.parse_chatParticipantAdmin($0) }
    dict[1567990072] = { return Api.updates.Difference.parse_differenceEmpty($0) }
    dict[16030880] = { return Api.updates.Difference.parse_difference($0) }
    dict[-1459938943] = { return Api.updates.Difference.parse_differenceSlice($0) }
    dict[1258196845] = { return Api.updates.Difference.parse_differenceTooLong($0) }
    dict[1462101002] = { return Api.CdnConfig.parse_cdnConfig($0) }
    dict[324435594] = { return Api.PageBlock.parse_pageBlockUnsupported($0) }
    dict[1890305021] = { return Api.PageBlock.parse_pageBlockTitle($0) }
    dict[-1879401953] = { return Api.PageBlock.parse_pageBlockSubtitle($0) }
    dict[-1162877472] = { return Api.PageBlock.parse_pageBlockAuthorDate($0) }
    dict[-1076861716] = { return Api.PageBlock.parse_pageBlockHeader($0) }
    dict[-248793375] = { return Api.PageBlock.parse_pageBlockSubheader($0) }
    dict[1182402406] = { return Api.PageBlock.parse_pageBlockParagraph($0) }
    dict[-1066346178] = { return Api.PageBlock.parse_pageBlockPreformatted($0) }
    dict[1216809369] = { return Api.PageBlock.parse_pageBlockFooter($0) }
    dict[-618614392] = { return Api.PageBlock.parse_pageBlockDivider($0) }
    dict[-837994576] = { return Api.PageBlock.parse_pageBlockAnchor($0) }
    dict[978896884] = { return Api.PageBlock.parse_pageBlockList($0) }
    dict[641563686] = { return Api.PageBlock.parse_pageBlockBlockquote($0) }
    dict[1329878739] = { return Api.PageBlock.parse_pageBlockPullquote($0) }
    dict[-372860542] = { return Api.PageBlock.parse_pageBlockPhoto($0) }
    dict[-640214938] = { return Api.PageBlock.parse_pageBlockVideo($0) }
    dict[972174080] = { return Api.PageBlock.parse_pageBlockCover($0) }
    dict[-840826671] = { return Api.PageBlock.parse_pageBlockEmbed($0) }
    dict[690781161] = { return Api.PageBlock.parse_pageBlockEmbedPost($0) }
    dict[145955919] = { return Api.PageBlock.parse_pageBlockCollage($0) }
    dict[319588707] = { return Api.PageBlock.parse_pageBlockSlideshow($0) }
    dict[-283684427] = { return Api.PageBlock.parse_pageBlockChannel($0) }
    dict[834148991] = { return Api.PageBlock.parse_pageBlockAudio($0) }
    dict[-614138572] = { return Api.account.TmpPassword.parse_tmpPassword($0) }
    dict[590459437] = { return Api.Photo.parse_photoEmpty($0) }
    dict[-1836524247] = { return Api.Photo.parse_photo($0) }
    dict[-1683826688] = { return Api.Chat.parse_chatEmpty($0) }
    dict[-652419756] = { return Api.Chat.parse_chat($0) }
    dict[120753115] = { return Api.Chat.parse_chatForbidden($0) }
    dict[681420594] = { return Api.Chat.parse_channelForbidden($0) }
    dict[-930515796] = { return Api.Chat.parse_channel($0) }
    dict[1516793212] = { return Api.ChatInvite.parse_chatInviteAlready($0) }
    dict[-613092008] = { return Api.ChatInvite.parse_chatInvite($0) }
    dict[1678812626] = { return Api.StickerSetCovered.parse_stickerSetCovered($0) }
    dict[872932635] = { return Api.StickerSetCovered.parse_stickerSetMultiCovered($0) }
    dict[1189204285] = { return Api.RecentMeUrl.parse_recentMeUrlUnknown($0) }
    dict[-1917045962] = { return Api.RecentMeUrl.parse_recentMeUrlUser($0) }
    dict[-1608834311] = { return Api.RecentMeUrl.parse_recentMeUrlChat($0) }
    dict[-347535331] = { return Api.RecentMeUrl.parse_recentMeUrlChatInvite($0) }
    dict[-1140172836] = { return Api.RecentMeUrl.parse_recentMeUrlStickerSet($0) }
    dict[-177282392] = { return Api.channels.ChannelParticipants.parse_channelParticipants($0) }
    dict[-266911767] = { return Api.channels.ChannelParticipants.parse_channelParticipantsNotModified($0) }
    dict[-599948721] = { return Api.RichText.parse_textEmpty($0) }
    dict[1950782688] = { return Api.RichText.parse_textPlain($0) }
    dict[1730456516] = { return Api.RichText.parse_textBold($0) }
    dict[-653089380] = { return Api.RichText.parse_textItalic($0) }
    dict[-1054465340] = { return Api.RichText.parse_textUnderline($0) }
    dict[-1678197867] = { return Api.RichText.parse_textStrike($0) }
    dict[1816074681] = { return Api.RichText.parse_textFixed($0) }
    dict[1009288385] = { return Api.RichText.parse_textUrl($0) }
    dict[-564523562] = { return Api.RichText.parse_textEmail($0) }
    dict[2120376535] = { return Api.RichText.parse_textConcat($0) }
    dict[253890367] = { return Api.UserFull.parse_userFull($0) }
    dict[-292807034] = { return Api.InputChannel.parse_inputChannelEmpty($0) }
    dict[-1343524562] = { return Api.InputChannel.parse_inputChannel($0) }
    dict[98092748] = { return Api.DcOption.parse_dcOption($0) }
    dict[2077869041] = { return Api.account.PasswordSettings.parse_passwordSettings($0) }
    dict[292985073] = { return Api.LangPackLanguage.parse_langPackLanguage($0) }
    dict[-1987579119] = { return Api.help.AppUpdate.parse_appUpdate($0) }
    dict[-1000708810] = { return Api.help.AppUpdate.parse_noAppUpdate($0) }
    dict[-209337866] = { return Api.LangPackDifference.parse_langPackDifference($0) }
    dict[-791039645] = { return Api.channels.ChannelParticipant.parse_channelParticipant($0) }
    dict[-1432995067] = { return Api.storage.FileType.parse_fileUnknown($0) }
    dict[1086091090] = { return Api.storage.FileType.parse_filePartial($0) }
    dict[8322574] = { return Api.storage.FileType.parse_fileJpeg($0) }
    dict[-891180321] = { return Api.storage.FileType.parse_fileGif($0) }
    dict[172975040] = { return Api.storage.FileType.parse_filePng($0) }
    dict[-1373745011] = { return Api.storage.FileType.parse_filePdf($0) }
    dict[1384777335] = { return Api.storage.FileType.parse_fileMp3($0) }
    dict[1258941372] = { return Api.storage.FileType.parse_fileMov($0) }
    dict[-1278304028] = { return Api.storage.FileType.parse_fileMp4($0) }
    dict[276907596] = { return Api.storage.FileType.parse_fileWebp($0) }
    dict[1338747336] = { return Api.messages.ArchivedStickers.parse_archivedStickers($0) }
    dict[406307684] = { return Api.InputEncryptedFile.parse_inputEncryptedFileEmpty($0) }
    dict[1690108678] = { return Api.InputEncryptedFile.parse_inputEncryptedFileUploaded($0) }
    dict[1511503333] = { return Api.InputEncryptedFile.parse_inputEncryptedFile($0) }
    dict[767652808] = { return Api.InputEncryptedFile.parse_inputEncryptedFileBigUploaded($0) }
    dict[1443858741] = { return Api.messages.SentEncryptedMessage.parse_sentEncryptedMessage($0) }
    dict[-1802240206] = { return Api.messages.SentEncryptedMessage.parse_sentEncryptedFile($0) }
    dict[1571494644] = { return Api.ExportedMessageLink.parse_exportedMessageLink($0) }
    dict[-855308010] = { return Api.auth.Authorization.parse_authorization($0) }
    dict[-181407105] = { return Api.InputFile.parse_inputFile($0) }
    dict[-95482955] = { return Api.InputFile.parse_inputFileBig($0) }
    dict[-1649296275] = { return Api.Peer.parse_peerUser($0) }
    dict[-1160714821] = { return Api.Peer.parse_peerChat($0) }
    dict[-1109531342] = { return Api.Peer.parse_peerChannel($0) }
    dict[-1868808300] = { return Api.PaymentRequestedInfo.parse_paymentRequestedInfo($0) }
    dict[164646985] = { return Api.UserStatus.parse_userStatusEmpty($0) }
    dict[-306628279] = { return Api.UserStatus.parse_userStatusOnline($0) }
    dict[9203775] = { return Api.UserStatus.parse_userStatusOffline($0) }
    dict[-496024847] = { return Api.UserStatus.parse_userStatusRecently($0) }
    dict[129960444] = { return Api.UserStatus.parse_userStatusLastWeek($0) }
    dict[2011940674] = { return Api.UserStatus.parse_userStatusLastMonth($0) }
    dict[-455150117] = { return Api.Dialog.parse_dialog($0) }
    dict[381645902] = { return Api.SendMessageAction.parse_sendMessageTypingAction($0) }
    dict[-44119819] = { return Api.SendMessageAction.parse_sendMessageCancelAction($0) }
    dict[-1584933265] = { return Api.SendMessageAction.parse_sendMessageRecordVideoAction($0) }
    dict[-378127636] = { return Api.SendMessageAction.parse_sendMessageUploadVideoAction($0) }
    dict[-718310409] = { return Api.SendMessageAction.parse_sendMessageRecordAudioAction($0) }
    dict[-212740181] = { return Api.SendMessageAction.parse_sendMessageUploadAudioAction($0) }
    dict[-774682074] = { return Api.SendMessageAction.parse_sendMessageUploadPhotoAction($0) }
    dict[-1441998364] = { return Api.SendMessageAction.parse_sendMessageUploadDocumentAction($0) }
    dict[393186209] = { return Api.SendMessageAction.parse_sendMessageGeoLocationAction($0) }
    dict[1653390447] = { return Api.SendMessageAction.parse_sendMessageChooseContactAction($0) }
    dict[-580219064] = { return Api.SendMessageAction.parse_sendMessageGamePlayAction($0) }
    dict[-1997373508] = { return Api.SendMessageAction.parse_sendMessageRecordRoundAction($0) }
    dict[-1150187996] = { return Api.SendMessageAction.parse_sendMessageUploadRoundAction($0) }
    dict[-1137792208] = { return Api.PrivacyKey.parse_privacyKeyStatusTimestamp($0) }
    dict[1343122938] = { return Api.PrivacyKey.parse_privacyKeyChatInvite($0) }
    dict[1030105979] = { return Api.PrivacyKey.parse_privacyKeyPhoneCall($0) }
    dict[522914557] = { return Api.Update.parse_updateNewMessage($0) }
    dict[1318109142] = { return Api.Update.parse_updateMessageID($0) }
    dict[-1576161051] = { return Api.Update.parse_updateDeleteMessages($0) }
    dict[1548249383] = { return Api.Update.parse_updateUserTyping($0) }
    dict[-1704596961] = { return Api.Update.parse_updateChatUserTyping($0) }
    dict[125178264] = { return Api.Update.parse_updateChatParticipants($0) }
    dict[469489699] = { return Api.Update.parse_updateUserStatus($0) }
    dict[-1489818765] = { return Api.Update.parse_updateUserName($0) }
    dict[-1791935732] = { return Api.Update.parse_updateUserPhoto($0) }
    dict[628472761] = { return Api.Update.parse_updateContactRegistered($0) }
    dict[-1657903163] = { return Api.Update.parse_updateContactLink($0) }
    dict[314359194] = { return Api.Update.parse_updateNewEncryptedMessage($0) }
    dict[386986326] = { return Api.Update.parse_updateEncryptedChatTyping($0) }
    dict[-1264392051] = { return Api.Update.parse_updateEncryption($0) }
    dict[956179895] = { return Api.Update.parse_updateEncryptedMessagesRead($0) }
    dict[-364179876] = { return Api.Update.parse_updateChatParticipantAdd($0) }
    dict[1851755554] = { return Api.Update.parse_updateChatParticipantDelete($0) }
    dict[-1906403213] = { return Api.Update.parse_updateDcOptions($0) }
    dict[-2131957734] = { return Api.Update.parse_updateUserBlocked($0) }
    dict[-1094555409] = { return Api.Update.parse_updateNotifySettings($0) }
    dict[-337352679] = { return Api.Update.parse_updateServiceNotification($0) }
    dict[-298113238] = { return Api.Update.parse_updatePrivacy($0) }
    dict[314130811] = { return Api.Update.parse_updateUserPhone($0) }
    dict[-1721631396] = { return Api.Update.parse_updateReadHistoryInbox($0) }
    dict[791617983] = { return Api.Update.parse_updateReadHistoryOutbox($0) }
    dict[2139689491] = { return Api.Update.parse_updateWebPage($0) }
    dict[1757493555] = { return Api.Update.parse_updateReadMessagesContents($0) }
    dict[-352032773] = { return Api.Update.parse_updateChannelTooLong($0) }
    dict[-1227598250] = { return Api.Update.parse_updateChannel($0) }
    dict[1656358105] = { return Api.Update.parse_updateNewChannelMessage($0) }
    dict[1108669311] = { return Api.Update.parse_updateReadChannelInbox($0) }
    dict[-1015733815] = { return Api.Update.parse_updateDeleteChannelMessages($0) }
    dict[-1734268085] = { return Api.Update.parse_updateChannelMessageViews($0) }
    dict[1855224129] = { return Api.Update.parse_updateChatAdmins($0) }
    dict[-1232070311] = { return Api.Update.parse_updateChatParticipantAdmin($0) }
    dict[1753886890] = { return Api.Update.parse_updateNewStickerSet($0) }
    dict[196268545] = { return Api.Update.parse_updateStickerSetsOrder($0) }
    dict[1135492588] = { return Api.Update.parse_updateStickerSets($0) }
    dict[-1821035490] = { return Api.Update.parse_updateSavedGifs($0) }
    dict[1417832080] = { return Api.Update.parse_updateBotInlineQuery($0) }
    dict[239663460] = { return Api.Update.parse_updateBotInlineSend($0) }
    dict[457133559] = { return Api.Update.parse_updateEditChannelMessage($0) }
    dict[-1738988427] = { return Api.Update.parse_updateChannelPinnedMessage($0) }
    dict[-415938591] = { return Api.Update.parse_updateBotCallbackQuery($0) }
    dict[-469536605] = { return Api.Update.parse_updateEditMessage($0) }
    dict[-103646630] = { return Api.Update.parse_updateInlineBotCallbackQuery($0) }
    dict[634833351] = { return Api.Update.parse_updateReadChannelOutbox($0) }
    dict[-299124375] = { return Api.Update.parse_updateDraftMessage($0) }
    dict[1461528386] = { return Api.Update.parse_updateReadFeaturedStickers($0) }
    dict[-1706939360] = { return Api.Update.parse_updateRecentStickers($0) }
    dict[-1574314746] = { return Api.Update.parse_updateConfig($0) }
    dict[861169551] = { return Api.Update.parse_updatePtsChanged($0) }
    dict[1081547008] = { return Api.Update.parse_updateChannelWebPage($0) }
    dict[-2095595325] = { return Api.Update.parse_updateBotWebhookJSON($0) }
    dict[-1684914010] = { return Api.Update.parse_updateBotWebhookJSONQuery($0) }
    dict[-523384512] = { return Api.Update.parse_updateBotShippingQuery($0) }
    dict[1563376297] = { return Api.Update.parse_updateBotPrecheckoutQuery($0) }
    dict[-1425052898] = { return Api.Update.parse_updatePhoneCall($0) }
    dict[281165899] = { return Api.Update.parse_updateLangPackTooLong($0) }
    dict[1442983757] = { return Api.Update.parse_updateLangPack($0) }
    dict[-451831443] = { return Api.Update.parse_updateFavedStickers($0) }
    dict[-1987495099] = { return Api.Update.parse_updateChannelReadMessagesContents($0) }
    dict[1887741886] = { return Api.Update.parse_updateContactsReset($0) }
    dict[1893427255] = { return Api.Update.parse_updateChannelAvailableMessages($0) }
    dict[433225532] = { return Api.Update.parse_updateDialogPinned($0) }
    dict[-364071333] = { return Api.Update.parse_updatePinnedDialogs($0) }
    dict[1558266229] = { return Api.PopularContact.parse_popularContact($0) }
    dict[367766557] = { return Api.ChannelParticipant.parse_channelParticipant($0) }
    dict[-1557620115] = { return Api.ChannelParticipant.parse_channelParticipantSelf($0) }
    dict[-471670279] = { return Api.ChannelParticipant.parse_channelParticipantCreator($0) }
    dict[-1473271656] = { return Api.ChannelParticipant.parse_channelParticipantAdmin($0) }
    dict[573315206] = { return Api.ChannelParticipant.parse_channelParticipantBanned($0) }
    dict[471043349] = { return Api.contacts.Blocked.parse_blocked($0) }
    dict[-1878523231] = { return Api.contacts.Blocked.parse_blockedSlice($0) }
    dict[-55902537] = { return Api.InputDialogPeer.parse_inputDialogPeer($0) }
    dict[-994444869] = { return Api.Error.parse_error($0) }
    dict[-1560655744] = { return Api.KeyboardButton.parse_keyboardButton($0) }
    dict[629866245] = { return Api.KeyboardButton.parse_keyboardButtonUrl($0) }
    dict[1748655686] = { return Api.KeyboardButton.parse_keyboardButtonCallback($0) }
    dict[-1318425559] = { return Api.KeyboardButton.parse_keyboardButtonRequestPhone($0) }
    dict[-59151553] = { return Api.KeyboardButton.parse_keyboardButtonRequestGeoLocation($0) }
    dict[90744648] = { return Api.KeyboardButton.parse_keyboardButtonSwitchInline($0) }
    dict[1358175439] = { return Api.KeyboardButton.parse_keyboardButtonGame($0) }
    dict[-1344716869] = { return Api.KeyboardButton.parse_keyboardButtonBuy($0) }
    dict[-748155807] = { return Api.ContactStatus.parse_contactStatus($0) }
    dict[1679398724] = { return Api.SecureFile.parse_secureFileEmpty($0) }
    dict[-534283678] = { return Api.SecureFile.parse_secureFile($0) }
    dict[236446268] = { return Api.PhotoSize.parse_photoSizeEmpty($0) }
    dict[2009052699] = { return Api.PhotoSize.parse_photoSize($0) }
    dict[-374917894] = { return Api.PhotoSize.parse_photoCachedSize($0) }
    dict[-244016606] = { return Api.messages.Stickers.parse_stickersNotModified($0) }
    dict[-463889475] = { return Api.messages.Stickers.parse_stickers($0) }
    dict[1008755359] = { return Api.InlineBotSwitchPM.parse_inlineBotSwitchPM($0) }
    dict[223655517] = { return Api.messages.FoundStickerSets.parse_foundStickerSetsNotModified($0) }
    dict[1359533640] = { return Api.messages.FoundStickerSets.parse_foundStickerSets($0) }
    dict[1158290442] = { return Api.messages.FoundGifs.parse_foundGifs($0) }
    dict[2086234950] = { return Api.FileLocation.parse_fileLocationUnavailable($0) }
    dict[1406570614] = { return Api.FileLocation.parse_fileLocation($0) }
    dict[-1195615476] = { return Api.InputNotifyPeer.parse_inputNotifyPeer($0) }
    dict[423314455] = { return Api.InputNotifyPeer.parse_inputNotifyUsers($0) }
    dict[1251338318] = { return Api.InputNotifyPeer.parse_inputNotifyChats($0) }
    dict[-317144808] = { return Api.EncryptedMessage.parse_encryptedMessage($0) }
    dict[594758406] = { return Api.EncryptedMessage.parse_encryptedMessageService($0) }
    dict[-566281095] = { return Api.ChannelParticipantsFilter.parse_channelParticipantsRecent($0) }
    dict[-1268741783] = { return Api.ChannelParticipantsFilter.parse_channelParticipantsAdmins($0) }
    dict[-1328445861] = { return Api.ChannelParticipantsFilter.parse_channelParticipantsBots($0) }
    dict[338142689] = { return Api.ChannelParticipantsFilter.parse_channelParticipantsBanned($0) }
    dict[106343499] = { return Api.ChannelParticipantsFilter.parse_channelParticipantsSearch($0) }
    dict[-1548400251] = { return Api.ChannelParticipantsFilter.parse_channelParticipantsKicked($0) }
    dict[-350980120] = { return Api.WebPage.parse_webPageEmpty($0) }
    dict[-981018084] = { return Api.WebPage.parse_webPagePending($0) }
    dict[1594340540] = { return Api.WebPage.parse_webPage($0) }
    dict[-2054908813] = { return Api.WebPage.parse_webPageNotModified($0) }
    dict[1036876423] = { return Api.InputBotInlineMessage.parse_inputBotInlineMessageText($0) }
    dict[-190472735] = { return Api.InputBotInlineMessage.parse_inputBotInlineMessageMediaGeo($0) }
    dict[766443943] = { return Api.InputBotInlineMessage.parse_inputBotInlineMessageMediaContact($0) }
    dict[1262639204] = { return Api.InputBotInlineMessage.parse_inputBotInlineMessageGame($0) }
    dict[864077702] = { return Api.InputBotInlineMessage.parse_inputBotInlineMessageMediaAuto($0) }
    dict[1098628881] = { return Api.InputBotInlineMessage.parse_inputBotInlineMessageMediaVenue($0) }
    dict[2002815875] = { return Api.KeyboardButtonRow.parse_keyboardButtonRow($0) }
    dict[1434820921] = { return Api.StickerSet.parse_stickerSet($0) }
    dict[539045032] = { return Api.photos.Photo.parse_photo($0) }
    dict[-208488460] = { return Api.InputContact.parse_inputPhoneContact($0) }
    dict[-1419371685] = { return Api.TopPeerCategory.parse_topPeerCategoryBotsPM($0) }
    dict[344356834] = { return Api.TopPeerCategory.parse_topPeerCategoryBotsInline($0) }
    dict[104314861] = { return Api.TopPeerCategory.parse_topPeerCategoryCorrespondents($0) }
    dict[-1122524854] = { return Api.TopPeerCategory.parse_topPeerCategoryGroups($0) }
    dict[371037736] = { return Api.TopPeerCategory.parse_topPeerCategoryChannels($0) }
    dict[511092620] = { return Api.TopPeerCategory.parse_topPeerCategoryPhoneCalls($0) }
    dict[-1219778094] = { return Api.contacts.Contacts.parse_contactsNotModified($0) }
    dict[-353862078] = { return Api.contacts.Contacts.parse_contacts($0) }
    dict[-1798033689] = { return Api.ChannelMessagesFilter.parse_channelMessagesFilterEmpty($0) }
    dict[-847783593] = { return Api.ChannelMessagesFilter.parse_channelMessagesFilter($0) }
    dict[326715557] = { return Api.auth.PasswordRecovery.parse_passwordRecovery($0) }
    dict[-1803769784] = { return Api.messages.BotResults.parse_botResults($0) }
    dict[1928391342] = { return Api.InputDocument.parse_inputDocumentEmpty($0) }
    dict[410618194] = { return Api.InputDocument.parse_inputDocument($0) }
    dict[2131196633] = { return Api.contacts.ResolvedPeer.parse_resolvedPeer($0) }
    dict[-1964327229] = { return Api.SecureData.parse_secureData($0) }
    dict[-1771768449] = { return Api.InputMedia.parse_inputMediaEmpty($0) }
    dict[-104578748] = { return Api.InputMedia.parse_inputMediaGeoPoint($0) }
    dict[-1494984313] = { return Api.InputMedia.parse_inputMediaContact($0) }
    dict[1212395773] = { return Api.InputMedia.parse_inputMediaGifExternal($0) }
    dict[-750828557] = { return Api.InputMedia.parse_inputMediaGame($0) }
    dict[2065305999] = { return Api.InputMedia.parse_inputMediaGeoLive($0) }
    dict[-1052959727] = { return Api.InputMedia.parse_inputMediaVenue($0) }
    dict[-186607933] = { return Api.InputMedia.parse_inputMediaInvoice($0) }
    dict[505969924] = { return Api.InputMedia.parse_inputMediaUploadedPhoto($0) }
    dict[1530447553] = { return Api.InputMedia.parse_inputMediaUploadedDocument($0) }
    dict[-1279654347] = { return Api.InputMedia.parse_inputMediaPhoto($0) }
    dict[598418386] = { return Api.InputMedia.parse_inputMediaDocument($0) }
    dict[-440664550] = { return Api.InputMedia.parse_inputMediaPhotoExternal($0) }
    dict[-78455655] = { return Api.InputMedia.parse_inputMediaDocumentExternal($0) }
    dict[2134579434] = { return Api.InputPeer.parse_inputPeerEmpty($0) }
    dict[2107670217] = { return Api.InputPeer.parse_inputPeerSelf($0) }
    dict[396093539] = { return Api.InputPeer.parse_inputPeerChat($0) }
    dict[2072935910] = { return Api.InputPeer.parse_inputPeerUser($0) }
    dict[548253432] = { return Api.InputPeer.parse_inputPeerChannel($0) }
    dict[568808380] = { return Api.upload.WebFile.parse_webFile($0) }
    dict[-116274796] = { return Api.Contact.parse_contact($0) }
    dict[1648543603] = { return Api.FileHash.parse_fileHash($0) }
    dict[400266251] = { return Api.BotInlineResult.parse_botInlineMediaResult($0) }
    dict[295067450] = { return Api.BotInlineResult.parse_botInlineResult($0) }
    dict[911761060] = { return Api.messages.BotCallbackAnswer.parse_botCallbackAnswer($0) }
    dict[1314881805] = { return Api.payments.PaymentResult.parse_paymentResult($0) }
    dict[1800845601] = { return Api.payments.PaymentResult.parse_paymentVerficationNeeded($0) }
    dict[1694474197] = { return Api.messages.Chats.parse_chats($0) }
    dict[-1663561404] = { return Api.messages.Chats.parse_chatsSlice($0) }
    dict[482797855] = { return Api.InputSingleMedia.parse_inputSingleMedia($0) }
    dict[218751099] = { return Api.InputPrivacyRule.parse_inputPrivacyValueAllowContacts($0) }
    dict[407582158] = { return Api.InputPrivacyRule.parse_inputPrivacyValueAllowAll($0) }
    dict[320652927] = { return Api.InputPrivacyRule.parse_inputPrivacyValueAllowUsers($0) }
    dict[195371015] = { return Api.InputPrivacyRule.parse_inputPrivacyValueDisallowContacts($0) }
    dict[-697604407] = { return Api.InputPrivacyRule.parse_inputPrivacyValueDisallowAll($0) }
    dict[-1877932953] = { return Api.InputPrivacyRule.parse_inputPrivacyValueDisallowUsers($0) }
    dict[-1058912715] = { return Api.messages.DhConfig.parse_dhConfigNotModified($0) }
    dict[740433629] = { return Api.messages.DhConfig.parse_dhConfig($0) }
    dict[-421545947] = { return Api.ChannelAdminLogEventAction.parse_channelAdminLogEventActionChangeTitle($0) }
    dict[1427671598] = { return Api.ChannelAdminLogEventAction.parse_channelAdminLogEventActionChangeAbout($0) }
    dict[1783299128] = { return Api.ChannelAdminLogEventAction.parse_channelAdminLogEventActionChangeUsername($0) }
    dict[-1204857405] = { return Api.ChannelAdminLogEventAction.parse_channelAdminLogEventActionChangePhoto($0) }
    dict[460916654] = { return Api.ChannelAdminLogEventAction.parse_channelAdminLogEventActionToggleInvites($0) }
    dict[648939889] = { return Api.ChannelAdminLogEventAction.parse_channelAdminLogEventActionToggleSignatures($0) }
    dict[-370660328] = { return Api.ChannelAdminLogEventAction.parse_channelAdminLogEventActionUpdatePinned($0) }
    dict[1889215493] = { return Api.ChannelAdminLogEventAction.parse_channelAdminLogEventActionEditMessage($0) }
    dict[1121994683] = { return Api.ChannelAdminLogEventAction.parse_channelAdminLogEventActionDeleteMessage($0) }
    dict[405815507] = { return Api.ChannelAdminLogEventAction.parse_channelAdminLogEventActionParticipantJoin($0) }
    dict[-124291086] = { return Api.ChannelAdminLogEventAction.parse_channelAdminLogEventActionParticipantLeave($0) }
    dict[-484690728] = { return Api.ChannelAdminLogEventAction.parse_channelAdminLogEventActionParticipantInvite($0) }
    dict[-422036098] = { return Api.ChannelAdminLogEventAction.parse_channelAdminLogEventActionParticipantToggleBan($0) }
    dict[-714643696] = { return Api.ChannelAdminLogEventAction.parse_channelAdminLogEventActionParticipantToggleAdmin($0) }
    dict[-1312568665] = { return Api.ChannelAdminLogEventAction.parse_channelAdminLogEventActionChangeStickerSet($0) }
    dict[1599903217] = { return Api.ChannelAdminLogEventAction.parse_channelAdminLogEventActionTogglePreHistoryHidden($0) }
    dict[-543777747] = { return Api.auth.ExportedAuthorization.parse_exportedAuthorization($0) }
    dict[2103482845] = { return Api.SecurePlainData.parse_securePlainPhone($0) }
    dict[569137759] = { return Api.SecurePlainData.parse_securePlainEmail($0) }
    dict[-1269012015] = { return Api.messages.AffectedHistory.parse_affectedHistory($0) }
    dict[570402317] = { return Api.account.PasswordInputSettings.parse_passwordInputSettings($0) }
    dict[649453030] = { return Api.messages.MessageEditData.parse_messageEditData($0) }
    dict[-886477832] = { return Api.LabeledPrice.parse_labeledPrice($0) }
    dict[-438840932] = { return Api.messages.ChatFull.parse_chatFull($0) }
    dict[-1059442448] = { return Api.InputSecureValue.parse_inputSecureValue($0) }
    dict[1722786150] = { return Api.help.DeepLinkInfo.parse_deepLinkInfoEmpty($0) }
    dict[1783556146] = { return Api.help.DeepLinkInfo.parse_deepLinkInfo($0) }
    dict[-313079300] = { return Api.account.WebAuthorizations.parse_webAuthorizations($0) }
    dict[-236044656] = { return Api.help.TermsOfService.parse_termsOfService($0) }
    dict[1490799288] = { return Api.ReportReason.parse_inputReportReasonSpam($0) }
    dict[505595789] = { return Api.ReportReason.parse_inputReportReasonViolence($0) }
    dict[777640226] = { return Api.ReportReason.parse_inputReportReasonPornography($0) }
    dict[-512463606] = { return Api.ReportReason.parse_inputReportReasonOther($0) }
    dict[-247351839] = { return Api.InputEncryptedChat.parse_inputEncryptedChat($0) }
    dict[-1169445179] = { return Api.DraftMessage.parse_draftMessageEmpty($0) }
    dict[-40996577] = { return Api.DraftMessage.parse_draftMessage($0) }
    dict[1568467877] = { return Api.ChannelAdminRights.parse_channelAdminRights($0) }
    dict[-2128640689] = { return Api.account.SentEmailCode.parse_sentEmailCode($0) }
    dict[-1038136962] = { return Api.EncryptedFile.parse_encryptedFileEmpty($0) }
    dict[1248893260] = { return Api.EncryptedFile.parse_encryptedFile($0) }
    dict[1489977929] = { return Api.ChannelBannedRights.parse_channelBannedRights($0) }
    dict[-1613493288] = { return Api.NotifyPeer.parse_notifyPeer($0) }
    dict[-1261946036] = { return Api.NotifyPeer.parse_notifyUsers($0) }
    dict[-1073230141] = { return Api.NotifyPeer.parse_notifyChats($0) }
    dict[1335282456] = { return Api.InputPrivacyKey.parse_inputPrivacyKeyStatusTimestamp($0) }
    dict[-1107622874] = { return Api.InputPrivacyKey.parse_inputPrivacyKeyChatInvite($0) }
    dict[-88417185] = { return Api.InputPrivacyKey.parse_inputPrivacyKeyPhoneCall($0) }
    dict[235081943] = { return Api.help.RecentMeUrls.parse_recentMeUrls($0) }
    dict[-1606526075] = { return Api.ReplyMarkup.parse_replyKeyboardHide($0) }
    dict[-200242528] = { return Api.ReplyMarkup.parse_replyKeyboardForceReply($0) }
    dict[889353612] = { return Api.ReplyMarkup.parse_replyKeyboardMarkup($0) }
    dict[1218642516] = { return Api.ReplyMarkup.parse_replyInlineMarkup($0) }
    dict[1493171408] = { return Api.HighScore.parse_highScore($0) }
    dict[-305282981] = { return Api.TopPeer.parse_topPeer($0) }
    dict[986597452] = { return Api.contacts.Link.parse_link($0) }
    dict[-331270968] = { return Api.SecureValue.parse_secureValue($0) }
    dict[-316748368] = { return Api.SecureValueHash.parse_secureValueHash($0) }
    dict[1444661369] = { return Api.ContactBlocked.parse_contactBlocked($0) }
    dict[-2128698738] = { return Api.auth.CheckedPhone.parse_checkedPhone($0) }
    dict[-1182234929] = { return Api.InputUser.parse_inputUserEmpty($0) }
    dict[-138301121] = { return Api.InputUser.parse_inputUserSelf($0) }
    dict[-668391402] = { return Api.InputUser.parse_inputUser($0) }
    dict[-1908433218] = { return Api.Page.parse_pagePart($0) }
    dict[1433323434] = { return Api.Page.parse_pageFull($0) }
    dict[871426631] = { return Api.SecureCredentialsEncrypted.parse_secureCredentialsEncrypted($0) }
    dict[157948117] = { return Api.upload.File.parse_file($0) }
    dict[-242427324] = { return Api.upload.File.parse_fileCdnRedirect($0) }
    dict[182649427] = { return Api.MessageRange.parse_messageRange($0) }
    dict[946083368] = { return Api.messages.StickerSetInstallResult.parse_stickerSetInstallResultSuccess($0) }
    dict[904138920] = { return Api.messages.StickerSetInstallResult.parse_stickerSetInstallResultArchive($0) }
    dict[-2034927730] = { return Api.Config.parse_config($0) }
    dict[-75283823] = { return Api.TopPeerCategoryPeers.parse_topPeerCategoryPeers($0) }
    dict[-1107729093] = { return Api.Game.parse_game($0) }
    dict[-1032140601] = { return Api.BotCommand.parse_botCommand($0) }
    dict[-2066640507] = { return Api.messages.AffectedMessages.parse_affectedMessages($0) }
    dict[-402498398] = { return Api.messages.SavedGifs.parse_savedGifsNotModified($0) }
    dict[772213157] = { return Api.messages.SavedGifs.parse_savedGifs($0) }
    dict[-914167110] = { return Api.CdnPublicKey.parse_cdnPublicKey($0) }
    dict[53231223] = { return Api.InputGame.parse_inputGameID($0) }
    dict[-1020139510] = { return Api.InputGame.parse_inputGameShortName($0) }
    dict[-1502174430] = { return Api.InputMessage.parse_inputMessageID($0) }
    dict[-1160215659] = { return Api.InputMessage.parse_inputMessageReplyTo($0) }
    dict[-2037963464] = { return Api.InputMessage.parse_inputMessagePinned($0) }
    dict[-1564789301] = { return Api.PhoneCallProtocol.parse_phoneCallProtocol($0) }
    dict[-860866985] = { return Api.WallPaper.parse_wallPaper($0) }
    dict[1662091044] = { return Api.WallPaper.parse_wallPaperSolid($0) }
    dict[-1938715001] = { return Api.messages.Messages.parse_messages($0) }
    dict[189033187] = { return Api.messages.Messages.parse_messagesSlice($0) }
    dict[-1725551049] = { return Api.messages.Messages.parse_channelMessages($0) }
    dict[1951620897] = { return Api.messages.Messages.parse_messagesNotModified($0) }
    dict[-1022713000] = { return Api.Invoice.parse_invoice($0) }
    dict[-2122045747] = { return Api.PeerSettings.parse_peerSettings($0) }
    dict[1577067778] = { return Api.auth.SentCode.parse_sentCode($0) }
    dict[480546647] = { return Api.InputChatPhoto.parse_inputChatPhotoEmpty($0) }
    dict[-1837345356] = { return Api.InputChatPhoto.parse_inputChatUploadedPhoto($0) }
    dict[-1991004873] = { return Api.InputChatPhoto.parse_inputChatPhoto($0) }
    dict[-368917890] = { return Api.PaymentCharge.parse_paymentCharge($0) }
    dict[-484987010] = { return Api.Updates.parse_updatesTooLong($0) }
    dict[-1857044719] = { return Api.Updates.parse_updateShortMessage($0) }
    dict[377562760] = { return Api.Updates.parse_updateShortChatMessage($0) }
    dict[2027216577] = { return Api.Updates.parse_updateShort($0) }
    dict[1918567619] = { return Api.Updates.parse_updatesCombined($0) }
    dict[1957577280] = { return Api.Updates.parse_updates($0) }
    dict[301019932] = { return Api.Updates.parse_updateShortSentMessage($0) }
    dict[1038967584] = { return Api.MessageMedia.parse_messageMediaEmpty($0) }
    dict[1457575028] = { return Api.MessageMedia.parse_messageMediaGeo($0) }
    dict[1585262393] = { return Api.MessageMedia.parse_messageMediaContact($0) }
    dict[-1618676578] = { return Api.MessageMedia.parse_messageMediaUnsupported($0) }
    dict[-1557277184] = { return Api.MessageMedia.parse_messageMediaWebPage($0) }
    dict[-38694904] = { return Api.MessageMedia.parse_messageMediaGame($0) }
    dict[-2074799289] = { return Api.MessageMedia.parse_messageMediaInvoice($0) }
    dict[2084316681] = { return Api.MessageMedia.parse_messageMediaGeoLive($0) }
    dict[784356159] = { return Api.MessageMedia.parse_messageMediaVenue($0) }
    dict[1766936791] = { return Api.MessageMedia.parse_messageMediaPhoto($0) }
    dict[-1666158377] = { return Api.MessageMedia.parse_messageMediaDocument($0) }
    dict[-842892769] = { return Api.PaymentSavedCredentials.parse_paymentSavedCredentialsCard($0) }
    dict[1450380236] = { return Api.Null.parse_null($0) }
    dict[1923290508] = { return Api.auth.CodeType.parse_codeTypeSms($0) }
    dict[1948046307] = { return Api.auth.CodeType.parse_codeTypeCall($0) }
    dict[577556219] = { return Api.auth.CodeType.parse_codeTypeFlashCall($0) }
    dict[1815593308] = { return Api.DocumentAttribute.parse_documentAttributeImageSize($0) }
    dict[297109817] = { return Api.DocumentAttribute.parse_documentAttributeAnimated($0) }
    dict[1662637586] = { return Api.DocumentAttribute.parse_documentAttributeSticker($0) }
    dict[250621158] = { return Api.DocumentAttribute.parse_documentAttributeVideo($0) }
    dict[-1739392570] = { return Api.DocumentAttribute.parse_documentAttributeAudio($0) }
    dict[358154344] = { return Api.DocumentAttribute.parse_documentAttributeFilename($0) }
    dict[-1744710921] = { return Api.DocumentAttribute.parse_documentAttributeHasStickers($0) }
    dict[307276766] = { return Api.account.Authorizations.parse_authorizations($0) }
    dict[935395612] = { return Api.ChatPhoto.parse_chatPhotoEmpty($0) }
    dict[1632839530] = { return Api.ChatPhoto.parse_chatPhoto($0) }
    dict[1062645411] = { return Api.payments.PaymentForm.parse_paymentForm($0) }
    dict[1342771681] = { return Api.payments.PaymentReceipt.parse_paymentReceipt($0) }
    dict[863093588] = { return Api.messages.PeerDialogs.parse_peerDialogs($0) }
    dict[-4838507] = { return Api.InputStickerSet.parse_inputStickerSetEmpty($0) }
    dict[-1645763991] = { return Api.InputStickerSet.parse_inputStickerSetID($0) }
    dict[-2044933984] = { return Api.InputStickerSet.parse_inputStickerSetShortName($0) }
    dict[-1729618630] = { return Api.BotInfo.parse_botInfo($0) }
    dict[-1519637954] = { return Api.updates.State.parse_state($0) }
    dict[372165663] = { return Api.FoundGif.parse_foundGif($0) }
    dict[-1670052855] = { return Api.FoundGif.parse_foundGifCached($0) }
    dict[537022650] = { return Api.User.parse_userEmpty($0) }
    dict[773059779] = { return Api.User.parse_user($0) }
    dict[-2082087340] = { return Api.Message.parse_messageEmpty($0) }
    dict[-1642487306] = { return Api.Message.parse_messageService($0) }
    dict[1157215293] = { return Api.Message.parse_message($0) }
    dict[186120336] = { return Api.messages.RecentStickers.parse_recentStickersNotModified($0) }
    dict[586395571] = { return Api.messages.RecentStickers.parse_recentStickers($0) }
    dict[342061462] = { return Api.InputFileLocation.parse_inputFileLocation($0) }
    dict[-182231723] = { return Api.InputFileLocation.parse_inputEncryptedFileLocation($0) }
    dict[1125058340] = { return Api.InputFileLocation.parse_inputDocumentFileLocation($0) }
    dict[-876089816] = { return Api.InputFileLocation.parse_inputSecureFileLocation($0) }
    dict[286776671] = { return Api.GeoPoint.parse_geoPointEmpty($0) }
    dict[541710092] = { return Api.GeoPoint.parse_geoPoint($0) }
    dict[506920429] = { return Api.InputPhoneCall.parse_inputPhoneCall($0) }
    dict[-1551583367] = { return Api.ReceivedNotifyMessage.parse_receivedNotifyMessage($0) }
    dict[-57668565] = { return Api.ChatParticipants.parse_chatParticipantsForbidden($0) }
    dict[1061556205] = { return Api.ChatParticipants.parse_chatParticipants($0) }
    dict[-1056001329] = { return Api.InputPaymentCredentials.parse_inputPaymentCredentialsSaved($0) }
    dict[873977640] = { return Api.InputPaymentCredentials.parse_inputPaymentCredentials($0) }
    dict[178373535] = { return Api.InputPaymentCredentials.parse_inputPaymentCredentialsApplePay($0) }
    dict[-905587442] = { return Api.InputPaymentCredentials.parse_inputPaymentCredentialsAndroidPay($0) }
    dict[-1239335713] = { return Api.ShippingOption.parse_shippingOption($0) }
    dict[859091184] = { return Api.InputSecureFile.parse_inputSecureFileUploaded($0) }
    dict[1399317950] = { return Api.InputSecureFile.parse_inputSecureFile($0) }
    dict[512535275] = { return Api.PostAddress.parse_postAddress($0) }
    dict[2104790276] = { return Api.DataJSON.parse_dataJSON($0) }
    dict[1251549527] = { return Api.InputStickeredMedia.parse_inputStickeredMediaPhoto($0) }
    dict[70813275] = { return Api.InputStickeredMedia.parse_inputStickeredMediaDocument($0) }
    dict[82699215] = { return Api.messages.FeaturedStickers.parse_featuredStickersNotModified($0) }
    dict[-123893531] = { return Api.messages.FeaturedStickers.parse_featuredStickers($0) }
    dict[-2048646399] = { return Api.PhoneCallDiscardReason.parse_phoneCallDiscardReasonMissed($0) }
    dict[-527056480] = { return Api.PhoneCallDiscardReason.parse_phoneCallDiscardReasonDisconnect($0) }
    dict[1471006352] = { return Api.PhoneCallDiscardReason.parse_phoneCallDiscardReasonHangup($0) }
    dict[-84416311] = { return Api.PhoneCallDiscardReason.parse_phoneCallDiscardReasonBusy($0) }
    dict[-1910892683] = { return Api.NearestDc.parse_nearestDc($0) }
    dict[-1916114267] = { return Api.photos.Photos.parse_photos($0) }
    dict[352657236] = { return Api.photos.Photos.parse_photosSlice($0) }
    dict[2010127419] = { return Api.contacts.ImportedContacts.parse_importedContacts($0) }
    dict[-1678949555] = { return Api.InputWebDocument.parse_inputWebDocument($0) }
    dict[-326966976] = { return Api.phone.PhoneCall.parse_phoneCall($0) }
    dict[995769920] = { return Api.ChannelAdminLogEvent.parse_channelAdminLogEvent($0) }
    dict[-1132882121] = { return Api.Bool.parse_boolFalse($0) }
    dict[-1720552011] = { return Api.Bool.parse_boolTrue($0) }
    dict[-892239370] = { return Api.LangPackString.parse_langPackString($0) }
    dict[1816636575] = { return Api.LangPackString.parse_langPackStringPluralized($0) }
    dict[695856818] = { return Api.LangPackString.parse_langPackStringDeleted($0) }
    dict[-1036396922] = { return Api.InputWebFileLocation.parse_inputWebFileLocation($0) }
    dict[1436466797] = { return Api.MessageFwdHeader.parse_messageFwdHeader($0) }
    dict[398898678] = { return Api.help.Support.parse_support($0) }
    dict[1474492012] = { return Api.MessagesFilter.parse_inputMessagesFilterEmpty($0) }
    dict[-1777752804] = { return Api.MessagesFilter.parse_inputMessagesFilterPhotos($0) }
    dict[-1614803355] = { return Api.MessagesFilter.parse_inputMessagesFilterVideo($0) }
    dict[1458172132] = { return Api.MessagesFilter.parse_inputMessagesFilterPhotoVideo($0) }
    dict[-648121413] = { return Api.MessagesFilter.parse_inputMessagesFilterPhotoVideoDocuments($0) }
    dict[-1629621880] = { return Api.MessagesFilter.parse_inputMessagesFilterDocument($0) }
    dict[2129714567] = { return Api.MessagesFilter.parse_inputMessagesFilterUrl($0) }
    dict[-3644025] = { return Api.MessagesFilter.parse_inputMessagesFilterGif($0) }
    dict[1358283666] = { return Api.MessagesFilter.parse_inputMessagesFilterVoice($0) }
    dict[928101534] = { return Api.MessagesFilter.parse_inputMessagesFilterMusic($0) }
    dict[975236280] = { return Api.MessagesFilter.parse_inputMessagesFilterChatPhotos($0) }
    dict[-2134272152] = { return Api.MessagesFilter.parse_inputMessagesFilterPhoneCalls($0) }
    dict[2054952868] = { return Api.MessagesFilter.parse_inputMessagesFilterRoundVoice($0) }
    dict[-1253451181] = { return Api.MessagesFilter.parse_inputMessagesFilterRoundVideo($0) }
    dict[-1040652646] = { return Api.MessagesFilter.parse_inputMessagesFilterMyMentions($0) }
    dict[1187706024] = { return Api.MessagesFilter.parse_inputMessagesFilterMyMentionsUnread($0) }
    dict[-419271411] = { return Api.MessagesFilter.parse_inputMessagesFilterGeo($0) }
    dict[-530392189] = { return Api.MessagesFilter.parse_inputMessagesFilterContacts($0) }
    dict[364538944] = { return Api.messages.Dialogs.parse_dialogs($0) }
    dict[1910543603] = { return Api.messages.Dialogs.parse_dialogsSlice($0) }
    dict[-290921362] = { return Api.upload.CdnFile.parse_cdnFileReuploadNeeded($0) }
    dict[-1449145777] = { return Api.upload.CdnFile.parse_cdnFile($0) }
    dict[415997816] = { return Api.help.InviteText.parse_inviteText($0) }
    dict[-1937807902] = { return Api.BotInlineMessage.parse_botInlineMessageText($0) }
    dict[982505656] = { return Api.BotInlineMessage.parse_botInlineMessageMediaGeo($0) }
    dict[904770772] = { return Api.BotInlineMessage.parse_botInlineMessageMediaContact($0) }
    dict[1984755728] = { return Api.BotInlineMessage.parse_botInlineMessageMediaAuto($0) }
    dict[-1970903652] = { return Api.BotInlineMessage.parse_botInlineMessageMediaVenue($0) }
    dict[-1673717362] = { return Api.InputPeerNotifySettings.parse_inputPeerNotifySettings($0) }
    dict[-1634752813] = { return Api.messages.FavedStickers.parse_favedStickersNotModified($0) }
    dict[-209768682] = { return Api.messages.FavedStickers.parse_favedStickers($0) }
    dict[1776236393] = { return Api.ExportedChatInvite.parse_chatInviteEmpty($0) }
    dict[-64092740] = { return Api.ExportedChatInvite.parse_chatInviteExported($0) }
    dict[-1177300496] = { return Api.account.AuthorizationForm.parse_authorizationForm($0) }
    dict[2079516406] = { return Api.Authorization.parse_authorization($0) }
    dict[-1361650766] = { return Api.MaskCoords.parse_maskCoords($0) }
    dict[-395967805] = { return Api.messages.AllStickers.parse_allStickersNotModified($0) }
    dict[-302170017] = { return Api.messages.AllStickers.parse_allStickers($0) }
    dict[-1655957568] = { return Api.PhoneConnection.parse_phoneConnection($0) }
    dict[-1194283041] = { return Api.AccountDaysTTL.parse_accountDaysTTL($0) }
    dict[-1658158621] = { return Api.SecureValueType.parse_secureValueTypePersonalDetails($0) }
    dict[1034709504] = { return Api.SecureValueType.parse_secureValueTypePassport($0) }
    dict[115615172] = { return Api.SecureValueType.parse_secureValueTypeDriverLicense($0) }
    dict[-1596951477] = { return Api.SecureValueType.parse_secureValueTypeIdentityCard($0) }
    dict[-874308058] = { return Api.SecureValueType.parse_secureValueTypeAddress($0) }
    dict[-63531698] = { return Api.SecureValueType.parse_secureValueTypeUtilityBill($0) }
    dict[-1995211763] = { return Api.SecureValueType.parse_secureValueTypeBankStatement($0) }
    dict[-1954007928] = { return Api.SecureValueType.parse_secureValueTypeRentalAgreement($0) }
    dict[-1289704741] = { return Api.SecureValueType.parse_secureValueTypePhone($0) }
    dict[-1908627474] = { return Api.SecureValueType.parse_secureValueTypeEmail($0) }
    dict[1587643126] = { return Api.account.Password.parse_noPassword($0) }
    dict[-798203965] = { return Api.account.Password.parse_password($0) }
    dict[-1462213465] = { return Api.InputBotInlineResult.parse_inputBotInlineResultPhoto($0) }
    dict[-459324] = { return Api.InputBotInlineResult.parse_inputBotInlineResultDocument($0) }
    dict[1336154098] = { return Api.InputBotInlineResult.parse_inputBotInlineResultGame($0) }
    dict[-2000710887] = { return Api.InputBotInlineResult.parse_inputBotInlineResult($0) }
    dict[1430961007] = { return Api.account.PrivacyRules.parse_privacyRules($0) }
    dict[-123988] = { return Api.PrivacyRule.parse_privacyValueAllowContacts($0) }
    dict[1698855810] = { return Api.PrivacyRule.parse_privacyValueAllowAll($0) }
    dict[1297858060] = { return Api.PrivacyRule.parse_privacyValueAllowUsers($0) }
    dict[-125240806] = { return Api.PrivacyRule.parse_privacyValueDisallowContacts($0) }
    dict[-1955338397] = { return Api.PrivacyRule.parse_privacyValueDisallowAll($0) }
    dict[209668535] = { return Api.PrivacyRule.parse_privacyValueDisallowUsers($0) }
    dict[-1230047312] = { return Api.MessageAction.parse_messageActionEmpty($0) }
    dict[-1503425638] = { return Api.MessageAction.parse_messageActionChatCreate($0) }
    dict[-1247687078] = { return Api.MessageAction.parse_messageActionChatEditTitle($0) }
    dict[2144015272] = { return Api.MessageAction.parse_messageActionChatEditPhoto($0) }
    dict[-1780220945] = { return Api.MessageAction.parse_messageActionChatDeletePhoto($0) }
    dict[1217033015] = { return Api.MessageAction.parse_messageActionChatAddUser($0) }
    dict[-1297179892] = { return Api.MessageAction.parse_messageActionChatDeleteUser($0) }
    dict[-123931160] = { return Api.MessageAction.parse_messageActionChatJoinedByLink($0) }
    dict[-1781355374] = { return Api.MessageAction.parse_messageActionChannelCreate($0) }
    dict[1371385889] = { return Api.MessageAction.parse_messageActionChatMigrateTo($0) }
    dict[-1336546578] = { return Api.MessageAction.parse_messageActionChannelMigrateFrom($0) }
    dict[-1799538451] = { return Api.MessageAction.parse_messageActionPinMessage($0) }
    dict[-1615153660] = { return Api.MessageAction.parse_messageActionHistoryClear($0) }
    dict[-1834538890] = { return Api.MessageAction.parse_messageActionGameScore($0) }
    dict[-1892568281] = { return Api.MessageAction.parse_messageActionPaymentSentMe($0) }
    dict[1080663248] = { return Api.MessageAction.parse_messageActionPaymentSent($0) }
    dict[-2132731265] = { return Api.MessageAction.parse_messageActionPhoneCall($0) }
    dict[1200788123] = { return Api.MessageAction.parse_messageActionScreenshotTaken($0) }
    dict[-85549226] = { return Api.MessageAction.parse_messageActionCustomAction($0) }
    dict[-1410748418] = { return Api.MessageAction.parse_messageActionBotAllowed($0) }
    dict[455635795] = { return Api.MessageAction.parse_messageActionSecureValuesSentMe($0) }
    dict[-648257196] = { return Api.MessageAction.parse_messageActionSecureValuesSent($0) }
    dict[1399245077] = { return Api.PhoneCall.parse_phoneCallEmpty($0) }
    dict[462375633] = { return Api.PhoneCall.parse_phoneCallWaiting($0) }
    dict[-2089411356] = { return Api.PhoneCall.parse_phoneCallRequested($0) }
    dict[1828732223] = { return Api.PhoneCall.parse_phoneCallAccepted($0) }
    dict[-1660057] = { return Api.PhoneCall.parse_phoneCall($0) }
    dict[1355435489] = { return Api.PhoneCall.parse_phoneCallDiscarded($0) }
    dict[-445792507] = { return Api.DialogPeer.parse_dialogPeer($0) }
    dict[1599050311] = { return Api.ContactLink.parse_contactLinkUnknown($0) }
    dict[-17968211] = { return Api.ContactLink.parse_contactLinkNone($0) }
    dict[646922073] = { return Api.ContactLink.parse_contactLinkHasPhone($0) }
    dict[-721239344] = { return Api.ContactLink.parse_contactLinkContact($0) }
    dict[-971322408] = { return Api.WebDocument.parse_webDocument($0) }
    dict[-104284986] = { return Api.WebDocument.parse_webDocumentNoProxy($0) }
    dict[-1290580579] = { return Api.contacts.Found.parse_found($0) }
    dict[-368018716] = { return Api.ChannelAdminLogEventsFilter.parse_channelAdminLogEventsFilter($0) }
    dict[1889961234] = { return Api.PeerNotifySettings.parse_peerNotifySettingsEmpty($0) }
    dict[-1353671392] = { return Api.PeerNotifySettings.parse_peerNotifySettings($0) }
    dict[-1995686519] = { return Api.InputBotInlineMessageID.parse_inputBotInlineMessageID($0) }
    dict[313694676] = { return Api.StickerPack.parse_stickerPack($0) }
    dict[1326562017] = { return Api.UserProfilePhoto.parse_userProfilePhotoEmpty($0) }
    dict[-715532088] = { return Api.UserProfilePhoto.parse_userProfilePhoto($0) }
    dict[-74456004] = { return Api.payments.SavedInfo.parse_savedInfo($0) }
    dict[1041346555] = { return Api.updates.ChannelDifference.parse_channelDifferenceEmpty($0) }
    dict[1788705589] = { return Api.updates.ChannelDifference.parse_channelDifferenceTooLong($0) }
    dict[543450958] = { return Api.updates.ChannelDifference.parse_channelDifference($0) }
    dict[-309659827] = { return Api.channels.AdminLogResults.parse_adminLogResults($0) }
    dict[1996904104] = { return Api.InputAppEvent.parse_inputAppEvent($0) }
    dict[-1148011883] = { return Api.MessageEntity.parse_messageEntityUnknown($0) }
    dict[-100378723] = { return Api.MessageEntity.parse_messageEntityMention($0) }
    dict[1868782349] = { return Api.MessageEntity.parse_messageEntityHashtag($0) }
    dict[1827637959] = { return Api.MessageEntity.parse_messageEntityBotCommand($0) }
    dict[1859134776] = { return Api.MessageEntity.parse_messageEntityUrl($0) }
    dict[1692693954] = { return Api.MessageEntity.parse_messageEntityEmail($0) }
    dict[-1117713463] = { return Api.MessageEntity.parse_messageEntityBold($0) }
    dict[-2106619040] = { return Api.MessageEntity.parse_messageEntityItalic($0) }
    dict[681706865] = { return Api.MessageEntity.parse_messageEntityCode($0) }
    dict[1938967520] = { return Api.MessageEntity.parse_messageEntityPre($0) }
    dict[1990644519] = { return Api.MessageEntity.parse_messageEntityTextUrl($0) }
    dict[892193368] = { return Api.MessageEntity.parse_messageEntityMentionName($0) }
    dict[546203849] = { return Api.MessageEntity.parse_inputMessageEntityMentionName($0) }
    dict[-1687559349] = { return Api.MessageEntity.parse_messageEntityPhone($0) }
    dict[1280209983] = { return Api.MessageEntity.parse_messageEntityCashtag($0) }
    dict[483901197] = { return Api.InputPhoto.parse_inputPhotoEmpty($0) }
    dict[-74070332] = { return Api.InputPhoto.parse_inputPhoto($0) }
    dict[-567906571] = { return Api.contacts.TopPeers.parse_topPeersNotModified($0) }
    dict[1891070632] = { return Api.contacts.TopPeers.parse_topPeers($0) }
    dict[1035688326] = { return Api.auth.SentCodeType.parse_sentCodeTypeApp($0) }
    dict[-1073693790] = { return Api.auth.SentCodeType.parse_sentCodeTypeSms($0) }
    dict[1398007207] = { return Api.auth.SentCodeType.parse_sentCodeTypeCall($0) }
    dict[-1425815847] = { return Api.auth.SentCodeType.parse_sentCodeTypeFlashCall($0) }
    dict[-1417756512] = { return Api.EncryptedChat.parse_encryptedChatEmpty($0) }
    dict[1006044124] = { return Api.EncryptedChat.parse_encryptedChatWaiting($0) }
    dict[-931638658] = { return Api.EncryptedChat.parse_encryptedChatRequested($0) }
    dict[-94974410] = { return Api.EncryptedChat.parse_encryptedChat($0) }
    dict[332848423] = { return Api.EncryptedChat.parse_encryptedChatDiscarded($0) }
    dict[922273905] = { return Api.Document.parse_documentEmpty($0) }
    dict[-2027738169] = { return Api.Document.parse_document($0) }
    dict[-1707344487] = { return Api.messages.HighScores.parse_highScores($0) }
    dict[-892779534] = { return Api.WebAuthorization.parse_webAuthorization($0) }
    dict[-805141448] = { return Api.ImportedContact.parse_importedContact($0) }
    return dict
}()

public struct Api {
    public static func parse(_ buffer: Buffer) -> Any? {
        let reader = BufferReader(buffer)
        if let signature = reader.readInt32() {
            return parse(reader, signature: signature)
        }
        return nil
    }
    
        static func parse(_ reader: BufferReader, signature: Int32) -> Any? {
            if let parser = parsers[signature] {
                return parser(reader)
            }
            else {
                Logger.shared.log("TL", "Type constructor \(String(signature, radix: 16, uppercase: false)) not found")
                return nil
            }
        }
        
        static func parseVector<T>(_ reader: BufferReader, elementSignature: Int32, elementType: T.Type) -> [T]? {
        if let count = reader.readInt32() {
            var array = [T]()
            var i: Int32 = 0
            while i < count {
                var signature = elementSignature
                if elementSignature == 0 {
                    if let unboxedSignature = reader.readInt32() {
                        signature = unboxedSignature
                    }
                    else {
                        return nil
                    }
                }
                if let item = Api.parse(reader, signature: signature) as? T {
                    array.append(item)
                }
                else {
                    return nil
                }
                i += 1
            }
            return array
        }
        return nil
    }
    
    public static func serializeObject(_ object: Any, buffer: Buffer, boxed: Swift.Bool) {
        switch object {
            case let _1 as Api.messages.StickerSet:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputGeoPoint:
                _1.serialize(buffer, boxed)
            case let _1 as Api.payments.ValidatedRequestedInfo:
                _1.serialize(buffer, boxed)
            case let _1 as Api.ChatFull:
                _1.serialize(buffer, boxed)
            case let _1 as Api.ChatParticipant:
                _1.serialize(buffer, boxed)
            case let _1 as Api.updates.Difference:
                _1.serialize(buffer, boxed)
            case let _1 as Api.CdnConfig:
                _1.serialize(buffer, boxed)
            case let _1 as Api.PageBlock:
                _1.serialize(buffer, boxed)
            case let _1 as Api.account.TmpPassword:
                _1.serialize(buffer, boxed)
            case let _1 as Api.Photo:
                _1.serialize(buffer, boxed)
            case let _1 as Api.Chat:
                _1.serialize(buffer, boxed)
            case let _1 as Api.ChatInvite:
                _1.serialize(buffer, boxed)
            case let _1 as Api.StickerSetCovered:
                _1.serialize(buffer, boxed)
            case let _1 as Api.RecentMeUrl:
                _1.serialize(buffer, boxed)
            case let _1 as Api.channels.ChannelParticipants:
                _1.serialize(buffer, boxed)
            case let _1 as Api.RichText:
                _1.serialize(buffer, boxed)
            case let _1 as Api.UserFull:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputChannel:
                _1.serialize(buffer, boxed)
            case let _1 as Api.DcOption:
                _1.serialize(buffer, boxed)
            case let _1 as Api.account.PasswordSettings:
                _1.serialize(buffer, boxed)
            case let _1 as Api.LangPackLanguage:
                _1.serialize(buffer, boxed)
            case let _1 as Api.help.AppUpdate:
                _1.serialize(buffer, boxed)
            case let _1 as Api.LangPackDifference:
                _1.serialize(buffer, boxed)
            case let _1 as Api.channels.ChannelParticipant:
                _1.serialize(buffer, boxed)
            case let _1 as Api.storage.FileType:
                _1.serialize(buffer, boxed)
            case let _1 as Api.messages.ArchivedStickers:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputEncryptedFile:
                _1.serialize(buffer, boxed)
            case let _1 as Api.messages.SentEncryptedMessage:
                _1.serialize(buffer, boxed)
            case let _1 as Api.ExportedMessageLink:
                _1.serialize(buffer, boxed)
            case let _1 as Api.auth.Authorization:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputFile:
                _1.serialize(buffer, boxed)
            case let _1 as Api.Peer:
                _1.serialize(buffer, boxed)
            case let _1 as Api.PaymentRequestedInfo:
                _1.serialize(buffer, boxed)
            case let _1 as Api.UserStatus:
                _1.serialize(buffer, boxed)
            case let _1 as Api.Dialog:
                _1.serialize(buffer, boxed)
            case let _1 as Api.SendMessageAction:
                _1.serialize(buffer, boxed)
            case let _1 as Api.PrivacyKey:
                _1.serialize(buffer, boxed)
            case let _1 as Api.Update:
                _1.serialize(buffer, boxed)
            case let _1 as Api.PopularContact:
                _1.serialize(buffer, boxed)
            case let _1 as Api.ChannelParticipant:
                _1.serialize(buffer, boxed)
            case let _1 as Api.contacts.Blocked:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputDialogPeer:
                _1.serialize(buffer, boxed)
            case let _1 as Api.Error:
                _1.serialize(buffer, boxed)
            case let _1 as Api.KeyboardButton:
                _1.serialize(buffer, boxed)
            case let _1 as Api.ContactStatus:
                _1.serialize(buffer, boxed)
            case let _1 as Api.SecureFile:
                _1.serialize(buffer, boxed)
            case let _1 as Api.PhotoSize:
                _1.serialize(buffer, boxed)
            case let _1 as Api.messages.Stickers:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InlineBotSwitchPM:
                _1.serialize(buffer, boxed)
            case let _1 as Api.messages.FoundStickerSets:
                _1.serialize(buffer, boxed)
            case let _1 as Api.messages.FoundGifs:
                _1.serialize(buffer, boxed)
            case let _1 as Api.FileLocation:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputNotifyPeer:
                _1.serialize(buffer, boxed)
            case let _1 as Api.EncryptedMessage:
                _1.serialize(buffer, boxed)
            case let _1 as Api.ChannelParticipantsFilter:
                _1.serialize(buffer, boxed)
            case let _1 as Api.WebPage:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputBotInlineMessage:
                _1.serialize(buffer, boxed)
            case let _1 as Api.KeyboardButtonRow:
                _1.serialize(buffer, boxed)
            case let _1 as Api.StickerSet:
                _1.serialize(buffer, boxed)
            case let _1 as Api.photos.Photo:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputContact:
                _1.serialize(buffer, boxed)
            case let _1 as Api.TopPeerCategory:
                _1.serialize(buffer, boxed)
            case let _1 as Api.contacts.Contacts:
                _1.serialize(buffer, boxed)
            case let _1 as Api.ChannelMessagesFilter:
                _1.serialize(buffer, boxed)
            case let _1 as Api.auth.PasswordRecovery:
                _1.serialize(buffer, boxed)
            case let _1 as Api.messages.BotResults:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputDocument:
                _1.serialize(buffer, boxed)
            case let _1 as Api.contacts.ResolvedPeer:
                _1.serialize(buffer, boxed)
            case let _1 as Api.SecureData:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputMedia:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputPeer:
                _1.serialize(buffer, boxed)
            case let _1 as Api.upload.WebFile:
                _1.serialize(buffer, boxed)
            case let _1 as Api.Contact:
                _1.serialize(buffer, boxed)
            case let _1 as Api.FileHash:
                _1.serialize(buffer, boxed)
            case let _1 as Api.BotInlineResult:
                _1.serialize(buffer, boxed)
            case let _1 as Api.messages.BotCallbackAnswer:
                _1.serialize(buffer, boxed)
            case let _1 as Api.payments.PaymentResult:
                _1.serialize(buffer, boxed)
            case let _1 as Api.messages.Chats:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputSingleMedia:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputPrivacyRule:
                _1.serialize(buffer, boxed)
            case let _1 as Api.messages.DhConfig:
                _1.serialize(buffer, boxed)
            case let _1 as Api.ChannelAdminLogEventAction:
                _1.serialize(buffer, boxed)
            case let _1 as Api.auth.ExportedAuthorization:
                _1.serialize(buffer, boxed)
            case let _1 as Api.SecurePlainData:
                _1.serialize(buffer, boxed)
            case let _1 as Api.messages.AffectedHistory:
                _1.serialize(buffer, boxed)
            case let _1 as Api.account.PasswordInputSettings:
                _1.serialize(buffer, boxed)
            case let _1 as Api.messages.MessageEditData:
                _1.serialize(buffer, boxed)
            case let _1 as Api.LabeledPrice:
                _1.serialize(buffer, boxed)
            case let _1 as Api.messages.ChatFull:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputSecureValue:
                _1.serialize(buffer, boxed)
            case let _1 as Api.help.DeepLinkInfo:
                _1.serialize(buffer, boxed)
            case let _1 as Api.account.WebAuthorizations:
                _1.serialize(buffer, boxed)
            case let _1 as Api.help.TermsOfService:
                _1.serialize(buffer, boxed)
            case let _1 as Api.ReportReason:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputEncryptedChat:
                _1.serialize(buffer, boxed)
            case let _1 as Api.DraftMessage:
                _1.serialize(buffer, boxed)
            case let _1 as Api.ChannelAdminRights:
                _1.serialize(buffer, boxed)
            case let _1 as Api.account.SentEmailCode:
                _1.serialize(buffer, boxed)
            case let _1 as Api.EncryptedFile:
                _1.serialize(buffer, boxed)
            case let _1 as Api.ChannelBannedRights:
                _1.serialize(buffer, boxed)
            case let _1 as Api.NotifyPeer:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputPrivacyKey:
                _1.serialize(buffer, boxed)
            case let _1 as Api.help.RecentMeUrls:
                _1.serialize(buffer, boxed)
            case let _1 as Api.ReplyMarkup:
                _1.serialize(buffer, boxed)
            case let _1 as Api.HighScore:
                _1.serialize(buffer, boxed)
            case let _1 as Api.TopPeer:
                _1.serialize(buffer, boxed)
            case let _1 as Api.contacts.Link:
                _1.serialize(buffer, boxed)
            case let _1 as Api.SecureValue:
                _1.serialize(buffer, boxed)
            case let _1 as Api.SecureValueHash:
                _1.serialize(buffer, boxed)
            case let _1 as Api.ContactBlocked:
                _1.serialize(buffer, boxed)
            case let _1 as Api.auth.CheckedPhone:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputUser:
                _1.serialize(buffer, boxed)
            case let _1 as Api.Page:
                _1.serialize(buffer, boxed)
            case let _1 as Api.SecureCredentialsEncrypted:
                _1.serialize(buffer, boxed)
            case let _1 as Api.upload.File:
                _1.serialize(buffer, boxed)
            case let _1 as Api.MessageRange:
                _1.serialize(buffer, boxed)
            case let _1 as Api.messages.StickerSetInstallResult:
                _1.serialize(buffer, boxed)
            case let _1 as Api.Config:
                _1.serialize(buffer, boxed)
            case let _1 as Api.TopPeerCategoryPeers:
                _1.serialize(buffer, boxed)
            case let _1 as Api.Game:
                _1.serialize(buffer, boxed)
            case let _1 as Api.BotCommand:
                _1.serialize(buffer, boxed)
            case let _1 as Api.messages.AffectedMessages:
                _1.serialize(buffer, boxed)
            case let _1 as Api.messages.SavedGifs:
                _1.serialize(buffer, boxed)
            case let _1 as Api.CdnPublicKey:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputGame:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputMessage:
                _1.serialize(buffer, boxed)
            case let _1 as Api.PhoneCallProtocol:
                _1.serialize(buffer, boxed)
            case let _1 as Api.WallPaper:
                _1.serialize(buffer, boxed)
            case let _1 as Api.messages.Messages:
                _1.serialize(buffer, boxed)
            case let _1 as Api.Invoice:
                _1.serialize(buffer, boxed)
            case let _1 as Api.PeerSettings:
                _1.serialize(buffer, boxed)
            case let _1 as Api.auth.SentCode:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputChatPhoto:
                _1.serialize(buffer, boxed)
            case let _1 as Api.PaymentCharge:
                _1.serialize(buffer, boxed)
            case let _1 as Api.Updates:
                _1.serialize(buffer, boxed)
            case let _1 as Api.MessageMedia:
                _1.serialize(buffer, boxed)
            case let _1 as Api.PaymentSavedCredentials:
                _1.serialize(buffer, boxed)
            case let _1 as Api.Null:
                _1.serialize(buffer, boxed)
            case let _1 as Api.auth.CodeType:
                _1.serialize(buffer, boxed)
            case let _1 as Api.DocumentAttribute:
                _1.serialize(buffer, boxed)
            case let _1 as Api.account.Authorizations:
                _1.serialize(buffer, boxed)
            case let _1 as Api.ChatPhoto:
                _1.serialize(buffer, boxed)
            case let _1 as Api.payments.PaymentForm:
                _1.serialize(buffer, boxed)
            case let _1 as Api.payments.PaymentReceipt:
                _1.serialize(buffer, boxed)
            case let _1 as Api.messages.PeerDialogs:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputStickerSet:
                _1.serialize(buffer, boxed)
            case let _1 as Api.BotInfo:
                _1.serialize(buffer, boxed)
            case let _1 as Api.updates.State:
                _1.serialize(buffer, boxed)
            case let _1 as Api.FoundGif:
                _1.serialize(buffer, boxed)
            case let _1 as Api.User:
                _1.serialize(buffer, boxed)
            case let _1 as Api.Message:
                _1.serialize(buffer, boxed)
            case let _1 as Api.messages.RecentStickers:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputFileLocation:
                _1.serialize(buffer, boxed)
            case let _1 as Api.GeoPoint:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputPhoneCall:
                _1.serialize(buffer, boxed)
            case let _1 as Api.ReceivedNotifyMessage:
                _1.serialize(buffer, boxed)
            case let _1 as Api.ChatParticipants:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputPaymentCredentials:
                _1.serialize(buffer, boxed)
            case let _1 as Api.ShippingOption:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputSecureFile:
                _1.serialize(buffer, boxed)
            case let _1 as Api.PostAddress:
                _1.serialize(buffer, boxed)
            case let _1 as Api.DataJSON:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputStickeredMedia:
                _1.serialize(buffer, boxed)
            case let _1 as Api.messages.FeaturedStickers:
                _1.serialize(buffer, boxed)
            case let _1 as Api.PhoneCallDiscardReason:
                _1.serialize(buffer, boxed)
            case let _1 as Api.NearestDc:
                _1.serialize(buffer, boxed)
            case let _1 as Api.photos.Photos:
                _1.serialize(buffer, boxed)
            case let _1 as Api.contacts.ImportedContacts:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputWebDocument:
                _1.serialize(buffer, boxed)
            case let _1 as Api.phone.PhoneCall:
                _1.serialize(buffer, boxed)
            case let _1 as Api.ChannelAdminLogEvent:
                _1.serialize(buffer, boxed)
            case let _1 as Api.Bool:
                _1.serialize(buffer, boxed)
            case let _1 as Api.LangPackString:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputWebFileLocation:
                _1.serialize(buffer, boxed)
            case let _1 as Api.MessageFwdHeader:
                _1.serialize(buffer, boxed)
            case let _1 as Api.help.Support:
                _1.serialize(buffer, boxed)
            case let _1 as Api.MessagesFilter:
                _1.serialize(buffer, boxed)
            case let _1 as Api.messages.Dialogs:
                _1.serialize(buffer, boxed)
            case let _1 as Api.upload.CdnFile:
                _1.serialize(buffer, boxed)
            case let _1 as Api.help.InviteText:
                _1.serialize(buffer, boxed)
            case let _1 as Api.BotInlineMessage:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputPeerNotifySettings:
                _1.serialize(buffer, boxed)
            case let _1 as Api.messages.FavedStickers:
                _1.serialize(buffer, boxed)
            case let _1 as Api.ExportedChatInvite:
                _1.serialize(buffer, boxed)
            case let _1 as Api.account.AuthorizationForm:
                _1.serialize(buffer, boxed)
            case let _1 as Api.Authorization:
                _1.serialize(buffer, boxed)
            case let _1 as Api.MaskCoords:
                _1.serialize(buffer, boxed)
            case let _1 as Api.messages.AllStickers:
                _1.serialize(buffer, boxed)
            case let _1 as Api.PhoneConnection:
                _1.serialize(buffer, boxed)
            case let _1 as Api.AccountDaysTTL:
                _1.serialize(buffer, boxed)
            case let _1 as Api.SecureValueType:
                _1.serialize(buffer, boxed)
            case let _1 as Api.account.Password:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputBotInlineResult:
                _1.serialize(buffer, boxed)
            case let _1 as Api.account.PrivacyRules:
                _1.serialize(buffer, boxed)
            case let _1 as Api.PrivacyRule:
                _1.serialize(buffer, boxed)
            case let _1 as Api.MessageAction:
                _1.serialize(buffer, boxed)
            case let _1 as Api.PhoneCall:
                _1.serialize(buffer, boxed)
            case let _1 as Api.DialogPeer:
                _1.serialize(buffer, boxed)
            case let _1 as Api.ContactLink:
                _1.serialize(buffer, boxed)
            case let _1 as Api.WebDocument:
                _1.serialize(buffer, boxed)
            case let _1 as Api.contacts.Found:
                _1.serialize(buffer, boxed)
            case let _1 as Api.ChannelAdminLogEventsFilter:
                _1.serialize(buffer, boxed)
            case let _1 as Api.PeerNotifySettings:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputBotInlineMessageID:
                _1.serialize(buffer, boxed)
            case let _1 as Api.StickerPack:
                _1.serialize(buffer, boxed)
            case let _1 as Api.UserProfilePhoto:
                _1.serialize(buffer, boxed)
            case let _1 as Api.payments.SavedInfo:
                _1.serialize(buffer, boxed)
            case let _1 as Api.updates.ChannelDifference:
                _1.serialize(buffer, boxed)
            case let _1 as Api.channels.AdminLogResults:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputAppEvent:
                _1.serialize(buffer, boxed)
            case let _1 as Api.MessageEntity:
                _1.serialize(buffer, boxed)
            case let _1 as Api.InputPhoto:
                _1.serialize(buffer, boxed)
            case let _1 as Api.contacts.TopPeers:
                _1.serialize(buffer, boxed)
            case let _1 as Api.auth.SentCodeType:
                _1.serialize(buffer, boxed)
            case let _1 as Api.EncryptedChat:
                _1.serialize(buffer, boxed)
            case let _1 as Api.Document:
                _1.serialize(buffer, boxed)
            case let _1 as Api.messages.HighScores:
                _1.serialize(buffer, boxed)
            case let _1 as Api.WebAuthorization:
                _1.serialize(buffer, boxed)
            case let _1 as Api.ImportedContact:
                _1.serialize(buffer, boxed)
            default:
                break
        }
    }

}
public extension Api {
public struct messages {
    public enum StickerSet {
        case stickerSet(set: Api.StickerSet, packs: [Api.StickerPack], documents: [Api.Document])
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .stickerSet(let set, let packs, let documents):
                    if boxed {
                        buffer.appendInt32(-1240849242)
                    }
                    set.serialize(buffer, true)
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(packs.count))
                    for item in packs {
                        item.serialize(buffer, true)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(documents.count))
                    for item in documents {
                        item.serialize(buffer, true)
                    }
                    break
    }
    }
    
        static func parse_stickerSet(_ reader: BufferReader) -> StickerSet? {
            var _1: Api.StickerSet?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.StickerSet
            }
            var _2: [Api.StickerPack]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.StickerPack.self)
            }
            var _3: [Api.Document]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Document.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.messages.StickerSet.stickerSet(set: _1!, packs: _2!, documents: _3!)
            }
            else {
                return nil
            }
        }
    
    }
    public enum ArchivedStickers {
        case archivedStickers(count: Int32, sets: [Api.StickerSetCovered])
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .archivedStickers(let count, let sets):
                    if boxed {
                        buffer.appendInt32(1338747336)
                    }
                    serializeInt32(count, buffer: buffer, boxed: false)
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(sets.count))
                    for item in sets {
                        item.serialize(buffer, true)
                    }
                    break
    }
    }
    
        static func parse_archivedStickers(_ reader: BufferReader) -> ArchivedStickers? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.StickerSetCovered]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.StickerSetCovered.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.messages.ArchivedStickers.archivedStickers(count: _1!, sets: _2!)
            }
            else {
                return nil
            }
        }
    
    }
    public enum SentEncryptedMessage {
        case sentEncryptedMessage(date: Int32)
        case sentEncryptedFile(date: Int32, file: Api.EncryptedFile)
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .sentEncryptedMessage(let date):
                    if boxed {
                        buffer.appendInt32(1443858741)
                    }
                    serializeInt32(date, buffer: buffer, boxed: false)
                    break
                case .sentEncryptedFile(let date, let file):
                    if boxed {
                        buffer.appendInt32(-1802240206)
                    }
                    serializeInt32(date, buffer: buffer, boxed: false)
                    file.serialize(buffer, true)
                    break
    }
    }
    
        static func parse_sentEncryptedMessage(_ reader: BufferReader) -> SentEncryptedMessage? {
            var _1: Int32?
            _1 = reader.readInt32()
            let _c1 = _1 != nil
            if _c1 {
                return Api.messages.SentEncryptedMessage.sentEncryptedMessage(date: _1!)
            }
            else {
                return nil
            }
        }
        static func parse_sentEncryptedFile(_ reader: BufferReader) -> SentEncryptedMessage? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.EncryptedFile?
            if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.EncryptedFile
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.messages.SentEncryptedMessage.sentEncryptedFile(date: _1!, file: _2!)
            }
            else {
                return nil
            }
        }
    
    }
    public enum Stickers {
        case stickersNotModified
        case stickers(hash: Int32, stickers: [Api.Document])
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .stickersNotModified:
                    if boxed {
                        buffer.appendInt32(-244016606)
                    }
                    
                    break
                case .stickers(let hash, let stickers):
                    if boxed {
                        buffer.appendInt32(-463889475)
                    }
                    serializeInt32(hash, buffer: buffer, boxed: false)
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(stickers.count))
                    for item in stickers {
                        item.serialize(buffer, true)
                    }
                    break
    }
    }
    
        static func parse_stickersNotModified(_ reader: BufferReader) -> Stickers? {
            return Api.messages.Stickers.stickersNotModified
        }
        static func parse_stickers(_ reader: BufferReader) -> Stickers? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.Document]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Document.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.messages.Stickers.stickers(hash: _1!, stickers: _2!)
            }
            else {
                return nil
            }
        }
    
    }
    public enum FoundStickerSets {
        case foundStickerSetsNotModified
        case foundStickerSets(hash: Int32, sets: [Api.StickerSetCovered])
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .foundStickerSetsNotModified:
                    if boxed {
                        buffer.appendInt32(223655517)
                    }
                    
                    break
                case .foundStickerSets(let hash, let sets):
                    if boxed {
                        buffer.appendInt32(1359533640)
                    }
                    serializeInt32(hash, buffer: buffer, boxed: false)
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(sets.count))
                    for item in sets {
                        item.serialize(buffer, true)
                    }
                    break
    }
    }
    
        static func parse_foundStickerSetsNotModified(_ reader: BufferReader) -> FoundStickerSets? {
            return Api.messages.FoundStickerSets.foundStickerSetsNotModified
        }
        static func parse_foundStickerSets(_ reader: BufferReader) -> FoundStickerSets? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.StickerSetCovered]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.StickerSetCovered.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.messages.FoundStickerSets.foundStickerSets(hash: _1!, sets: _2!)
            }
            else {
                return nil
            }
        }
    
    }
    public enum FoundGifs {
        case foundGifs(nextOffset: Int32, results: [Api.FoundGif])
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .foundGifs(let nextOffset, let results):
                    if boxed {
                        buffer.appendInt32(1158290442)
                    }
                    serializeInt32(nextOffset, buffer: buffer, boxed: false)
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(results.count))
                    for item in results {
                        item.serialize(buffer, true)
                    }
                    break
    }
    }
    
        static func parse_foundGifs(_ reader: BufferReader) -> FoundGifs? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.FoundGif]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.FoundGif.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.messages.FoundGifs.foundGifs(nextOffset: _1!, results: _2!)
            }
            else {
                return nil
            }
        }
    
    }
    public enum BotResults {
        case botResults(flags: Int32, queryId: Int64, nextOffset: String?, switchPm: Api.InlineBotSwitchPM?, results: [Api.BotInlineResult], cacheTime: Int32, users: [Api.User])
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .botResults(let flags, let queryId, let nextOffset, let switchPm, let results, let cacheTime, let users):
                    if boxed {
                        buffer.appendInt32(-1803769784)
                    }
                    serializeInt32(flags, buffer: buffer, boxed: false)
                    serializeInt64(queryId, buffer: buffer, boxed: false)
                    if Int(flags) & Int(1 << 1) != 0 {serializeString(nextOffset!, buffer: buffer, boxed: false)}
                    if Int(flags) & Int(1 << 2) != 0 {switchPm!.serialize(buffer, true)}
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(results.count))
                    for item in results {
                        item.serialize(buffer, true)
                    }
                    serializeInt32(cacheTime, buffer: buffer, boxed: false)
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(users.count))
                    for item in users {
                        item.serialize(buffer, true)
                    }
                    break
    }
    }
    
        static func parse_botResults(_ reader: BufferReader) -> BotResults? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int64?
            _2 = reader.readInt64()
            var _3: String?
            if Int(_1!) & Int(1 << 1) != 0 {_3 = parseString(reader) }
            var _4: Api.InlineBotSwitchPM?
            if Int(_1!) & Int(1 << 2) != 0 {if let signature = reader.readInt32() {
                _4 = Api.parse(reader, signature: signature) as? Api.InlineBotSwitchPM
            } }
            var _5: [Api.BotInlineResult]?
            if let _ = reader.readInt32() {
                _5 = Api.parseVector(reader, elementSignature: 0, elementType: Api.BotInlineResult.self)
            }
            var _6: Int32?
            _6 = reader.readInt32()
            var _7: [Api.User]?
            if let _ = reader.readInt32() {
                _7 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = (Int(_1!) & Int(1 << 1) == 0) || _3 != nil
            let _c4 = (Int(_1!) & Int(1 << 2) == 0) || _4 != nil
            let _c5 = _5 != nil
            let _c6 = _6 != nil
            let _c7 = _7 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 && _c7 {
                return Api.messages.BotResults.botResults(flags: _1!, queryId: _2!, nextOffset: _3, switchPm: _4, results: _5!, cacheTime: _6!, users: _7!)
            }
            else {
                return nil
            }
        }
    
    }
    public enum BotCallbackAnswer {
        case botCallbackAnswer(flags: Int32, message: String?, url: String?, cacheTime: Int32)
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .botCallbackAnswer(let flags, let message, let url, let cacheTime):
                    if boxed {
                        buffer.appendInt32(911761060)
                    }
                    serializeInt32(flags, buffer: buffer, boxed: false)
                    if Int(flags) & Int(1 << 0) != 0 {serializeString(message!, buffer: buffer, boxed: false)}
                    if Int(flags) & Int(1 << 2) != 0 {serializeString(url!, buffer: buffer, boxed: false)}
                    serializeInt32(cacheTime, buffer: buffer, boxed: false)
                    break
    }
    }
    
        static func parse_botCallbackAnswer(_ reader: BufferReader) -> BotCallbackAnswer? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: String?
            if Int(_1!) & Int(1 << 0) != 0 {_2 = parseString(reader) }
            var _3: String?
            if Int(_1!) & Int(1 << 2) != 0 {_3 = parseString(reader) }
            var _4: Int32?
            _4 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = (Int(_1!) & Int(1 << 0) == 0) || _2 != nil
            let _c3 = (Int(_1!) & Int(1 << 2) == 0) || _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.messages.BotCallbackAnswer.botCallbackAnswer(flags: _1!, message: _2, url: _3, cacheTime: _4!)
            }
            else {
                return nil
            }
        }
    
    }
    public enum Chats {
        case chats(chats: [Api.Chat])
        case chatsSlice(count: Int32, chats: [Api.Chat])
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .chats(let chats):
                    if boxed {
                        buffer.appendInt32(1694474197)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(chats.count))
                    for item in chats {
                        item.serialize(buffer, true)
                    }
                    break
                case .chatsSlice(let count, let chats):
                    if boxed {
                        buffer.appendInt32(-1663561404)
                    }
                    serializeInt32(count, buffer: buffer, boxed: false)
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(chats.count))
                    for item in chats {
                        item.serialize(buffer, true)
                    }
                    break
    }
    }
    
        static func parse_chats(_ reader: BufferReader) -> Chats? {
            var _1: [Api.Chat]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Chat.self)
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.messages.Chats.chats(chats: _1!)
            }
            else {
                return nil
            }
        }
        static func parse_chatsSlice(_ reader: BufferReader) -> Chats? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.Chat]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Chat.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.messages.Chats.chatsSlice(count: _1!, chats: _2!)
            }
            else {
                return nil
            }
        }
    
    }
    public enum DhConfig {
        case dhConfigNotModified(random: Buffer)
        case dhConfig(g: Int32, p: Buffer, version: Int32, random: Buffer)
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .dhConfigNotModified(let random):
                    if boxed {
                        buffer.appendInt32(-1058912715)
                    }
                    serializeBytes(random, buffer: buffer, boxed: false)
                    break
                case .dhConfig(let g, let p, let version, let random):
                    if boxed {
                        buffer.appendInt32(740433629)
                    }
                    serializeInt32(g, buffer: buffer, boxed: false)
                    serializeBytes(p, buffer: buffer, boxed: false)
                    serializeInt32(version, buffer: buffer, boxed: false)
                    serializeBytes(random, buffer: buffer, boxed: false)
                    break
    }
    }
    
        static func parse_dhConfigNotModified(_ reader: BufferReader) -> DhConfig? {
            var _1: Buffer?
            _1 = parseBytes(reader)
            let _c1 = _1 != nil
            if _c1 {
                return Api.messages.DhConfig.dhConfigNotModified(random: _1!)
            }
            else {
                return nil
            }
        }
        static func parse_dhConfig(_ reader: BufferReader) -> DhConfig? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Buffer?
            _2 = parseBytes(reader)
            var _3: Int32?
            _3 = reader.readInt32()
            var _4: Buffer?
            _4 = parseBytes(reader)
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.messages.DhConfig.dhConfig(g: _1!, p: _2!, version: _3!, random: _4!)
            }
            else {
                return nil
            }
        }
    
    }
    public enum AffectedHistory {
        case affectedHistory(pts: Int32, ptsCount: Int32, offset: Int32)
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .affectedHistory(let pts, let ptsCount, let offset):
                    if boxed {
                        buffer.appendInt32(-1269012015)
                    }
                    serializeInt32(pts, buffer: buffer, boxed: false)
                    serializeInt32(ptsCount, buffer: buffer, boxed: false)
                    serializeInt32(offset, buffer: buffer, boxed: false)
                    break
    }
    }
    
        static func parse_affectedHistory(_ reader: BufferReader) -> AffectedHistory? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: Int32?
            _3 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.messages.AffectedHistory.affectedHistory(pts: _1!, ptsCount: _2!, offset: _3!)
            }
            else {
                return nil
            }
        }
    
    }
    public enum MessageEditData {
        case messageEditData(flags: Int32)
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .messageEditData(let flags):
                    if boxed {
                        buffer.appendInt32(649453030)
                    }
                    serializeInt32(flags, buffer: buffer, boxed: false)
                    break
    }
    }
    
        static func parse_messageEditData(_ reader: BufferReader) -> MessageEditData? {
            var _1: Int32?
            _1 = reader.readInt32()
            let _c1 = _1 != nil
            if _c1 {
                return Api.messages.MessageEditData.messageEditData(flags: _1!)
            }
            else {
                return nil
            }
        }
    
    }
    public enum ChatFull {
        case chatFull(fullChat: Api.ChatFull, chats: [Api.Chat], users: [Api.User])
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .chatFull(let fullChat, let chats, let users):
                    if boxed {
                        buffer.appendInt32(-438840932)
                    }
                    fullChat.serialize(buffer, true)
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(chats.count))
                    for item in chats {
                        item.serialize(buffer, true)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(users.count))
                    for item in users {
                        item.serialize(buffer, true)
                    }
                    break
    }
    }
    
        static func parse_chatFull(_ reader: BufferReader) -> ChatFull? {
            var _1: Api.ChatFull?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.ChatFull
            }
            var _2: [Api.Chat]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Chat.self)
            }
            var _3: [Api.User]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.messages.ChatFull.chatFull(fullChat: _1!, chats: _2!, users: _3!)
            }
            else {
                return nil
            }
        }
    
    }
    public enum StickerSetInstallResult {
        case stickerSetInstallResultSuccess
        case stickerSetInstallResultArchive(sets: [Api.StickerSetCovered])
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .stickerSetInstallResultSuccess:
                    if boxed {
                        buffer.appendInt32(946083368)
                    }
                    
                    break
                case .stickerSetInstallResultArchive(let sets):
                    if boxed {
                        buffer.appendInt32(904138920)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(sets.count))
                    for item in sets {
                        item.serialize(buffer, true)
                    }
                    break
    }
    }
    
        static func parse_stickerSetInstallResultSuccess(_ reader: BufferReader) -> StickerSetInstallResult? {
            return Api.messages.StickerSetInstallResult.stickerSetInstallResultSuccess
        }
        static func parse_stickerSetInstallResultArchive(_ reader: BufferReader) -> StickerSetInstallResult? {
            var _1: [Api.StickerSetCovered]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.StickerSetCovered.self)
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.messages.StickerSetInstallResult.stickerSetInstallResultArchive(sets: _1!)
            }
            else {
                return nil
            }
        }
    
    }
    public enum AffectedMessages {
        case affectedMessages(pts: Int32, ptsCount: Int32)
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .affectedMessages(let pts, let ptsCount):
                    if boxed {
                        buffer.appendInt32(-2066640507)
                    }
                    serializeInt32(pts, buffer: buffer, boxed: false)
                    serializeInt32(ptsCount, buffer: buffer, boxed: false)
                    break
    }
    }
    
        static func parse_affectedMessages(_ reader: BufferReader) -> AffectedMessages? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int32?
            _2 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.messages.AffectedMessages.affectedMessages(pts: _1!, ptsCount: _2!)
            }
            else {
                return nil
            }
        }
    
    }
    public enum SavedGifs {
        case savedGifsNotModified
        case savedGifs(hash: Int32, gifs: [Api.Document])
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .savedGifsNotModified:
                    if boxed {
                        buffer.appendInt32(-402498398)
                    }
                    
                    break
                case .savedGifs(let hash, let gifs):
                    if boxed {
                        buffer.appendInt32(772213157)
                    }
                    serializeInt32(hash, buffer: buffer, boxed: false)
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(gifs.count))
                    for item in gifs {
                        item.serialize(buffer, true)
                    }
                    break
    }
    }
    
        static func parse_savedGifsNotModified(_ reader: BufferReader) -> SavedGifs? {
            return Api.messages.SavedGifs.savedGifsNotModified
        }
        static func parse_savedGifs(_ reader: BufferReader) -> SavedGifs? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.Document]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Document.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.messages.SavedGifs.savedGifs(hash: _1!, gifs: _2!)
            }
            else {
                return nil
            }
        }
    
    }
    public enum Messages {
        case messages(messages: [Api.Message], chats: [Api.Chat], users: [Api.User])
        case messagesSlice(count: Int32, messages: [Api.Message], chats: [Api.Chat], users: [Api.User])
        case channelMessages(flags: Int32, pts: Int32, count: Int32, messages: [Api.Message], chats: [Api.Chat], users: [Api.User])
        case messagesNotModified(count: Int32)
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .messages(let messages, let chats, let users):
                    if boxed {
                        buffer.appendInt32(-1938715001)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(messages.count))
                    for item in messages {
                        item.serialize(buffer, true)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(chats.count))
                    for item in chats {
                        item.serialize(buffer, true)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(users.count))
                    for item in users {
                        item.serialize(buffer, true)
                    }
                    break
                case .messagesSlice(let count, let messages, let chats, let users):
                    if boxed {
                        buffer.appendInt32(189033187)
                    }
                    serializeInt32(count, buffer: buffer, boxed: false)
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(messages.count))
                    for item in messages {
                        item.serialize(buffer, true)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(chats.count))
                    for item in chats {
                        item.serialize(buffer, true)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(users.count))
                    for item in users {
                        item.serialize(buffer, true)
                    }
                    break
                case .channelMessages(let flags, let pts, let count, let messages, let chats, let users):
                    if boxed {
                        buffer.appendInt32(-1725551049)
                    }
                    serializeInt32(flags, buffer: buffer, boxed: false)
                    serializeInt32(pts, buffer: buffer, boxed: false)
                    serializeInt32(count, buffer: buffer, boxed: false)
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(messages.count))
                    for item in messages {
                        item.serialize(buffer, true)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(chats.count))
                    for item in chats {
                        item.serialize(buffer, true)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(users.count))
                    for item in users {
                        item.serialize(buffer, true)
                    }
                    break
                case .messagesNotModified(let count):
                    if boxed {
                        buffer.appendInt32(1951620897)
                    }
                    serializeInt32(count, buffer: buffer, boxed: false)
                    break
    }
    }
    
        static func parse_messages(_ reader: BufferReader) -> Messages? {
            var _1: [Api.Message]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Message.self)
            }
            var _2: [Api.Chat]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Chat.self)
            }
            var _3: [Api.User]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.messages.Messages.messages(messages: _1!, chats: _2!, users: _3!)
            }
            else {
                return nil
            }
        }
        static func parse_messagesSlice(_ reader: BufferReader) -> Messages? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.Message]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Message.self)
            }
            var _3: [Api.Chat]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Chat.self)
            }
            var _4: [Api.User]?
            if let _ = reader.readInt32() {
                _4 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.messages.Messages.messagesSlice(count: _1!, messages: _2!, chats: _3!, users: _4!)
            }
            else {
                return nil
            }
        }
        static func parse_channelMessages(_ reader: BufferReader) -> Messages? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: Int32?
            _3 = reader.readInt32()
            var _4: [Api.Message]?
            if let _ = reader.readInt32() {
                _4 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Message.self)
            }
            var _5: [Api.Chat]?
            if let _ = reader.readInt32() {
                _5 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Chat.self)
            }
            var _6: [Api.User]?
            if let _ = reader.readInt32() {
                _6 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            let _c6 = _6 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 {
                return Api.messages.Messages.channelMessages(flags: _1!, pts: _2!, count: _3!, messages: _4!, chats: _5!, users: _6!)
            }
            else {
                return nil
            }
        }
        static func parse_messagesNotModified(_ reader: BufferReader) -> Messages? {
            var _1: Int32?
            _1 = reader.readInt32()
            let _c1 = _1 != nil
            if _c1 {
                return Api.messages.Messages.messagesNotModified(count: _1!)
            }
            else {
                return nil
            }
        }
    
    }
    public enum PeerDialogs {
        case peerDialogs(dialogs: [Api.Dialog], messages: [Api.Message], chats: [Api.Chat], users: [Api.User], state: Api.updates.State)
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .peerDialogs(let dialogs, let messages, let chats, let users, let state):
                    if boxed {
                        buffer.appendInt32(863093588)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(dialogs.count))
                    for item in dialogs {
                        item.serialize(buffer, true)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(messages.count))
                    for item in messages {
                        item.serialize(buffer, true)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(chats.count))
                    for item in chats {
                        item.serialize(buffer, true)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(users.count))
                    for item in users {
                        item.serialize(buffer, true)
                    }
                    state.serialize(buffer, true)
                    break
    }
    }
    
        static func parse_peerDialogs(_ reader: BufferReader) -> PeerDialogs? {
            var _1: [Api.Dialog]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Dialog.self)
            }
            var _2: [Api.Message]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Message.self)
            }
            var _3: [Api.Chat]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Chat.self)
            }
            var _4: [Api.User]?
            if let _ = reader.readInt32() {
                _4 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            var _5: Api.updates.State?
            if let signature = reader.readInt32() {
                _5 = Api.parse(reader, signature: signature) as? Api.updates.State
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 {
                return Api.messages.PeerDialogs.peerDialogs(dialogs: _1!, messages: _2!, chats: _3!, users: _4!, state: _5!)
            }
            else {
                return nil
            }
        }
    
    }
    public enum RecentStickers {
        case recentStickersNotModified
        case recentStickers(hash: Int32, packs: [Api.StickerPack], stickers: [Api.Document], dates: [Int32])
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .recentStickersNotModified:
                    if boxed {
                        buffer.appendInt32(186120336)
                    }
                    
                    break
                case .recentStickers(let hash, let packs, let stickers, let dates):
                    if boxed {
                        buffer.appendInt32(586395571)
                    }
                    serializeInt32(hash, buffer: buffer, boxed: false)
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(packs.count))
                    for item in packs {
                        item.serialize(buffer, true)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(stickers.count))
                    for item in stickers {
                        item.serialize(buffer, true)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(dates.count))
                    for item in dates {
                        serializeInt32(item, buffer: buffer, boxed: false)
                    }
                    break
    }
    }
    
        static func parse_recentStickersNotModified(_ reader: BufferReader) -> RecentStickers? {
            return Api.messages.RecentStickers.recentStickersNotModified
        }
        static func parse_recentStickers(_ reader: BufferReader) -> RecentStickers? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.StickerPack]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.StickerPack.self)
            }
            var _3: [Api.Document]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Document.self)
            }
            var _4: [Int32]?
            if let _ = reader.readInt32() {
                _4 = Api.parseVector(reader, elementSignature: -1471112230, elementType: Int32.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.messages.RecentStickers.recentStickers(hash: _1!, packs: _2!, stickers: _3!, dates: _4!)
            }
            else {
                return nil
            }
        }
    
    }
    public enum FeaturedStickers {
        case featuredStickersNotModified
        case featuredStickers(hash: Int32, sets: [Api.StickerSetCovered], unread: [Int64])
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .featuredStickersNotModified:
                    if boxed {
                        buffer.appendInt32(82699215)
                    }
                    
                    break
                case .featuredStickers(let hash, let sets, let unread):
                    if boxed {
                        buffer.appendInt32(-123893531)
                    }
                    serializeInt32(hash, buffer: buffer, boxed: false)
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(sets.count))
                    for item in sets {
                        item.serialize(buffer, true)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(unread.count))
                    for item in unread {
                        serializeInt64(item, buffer: buffer, boxed: false)
                    }
                    break
    }
    }
    
        static func parse_featuredStickersNotModified(_ reader: BufferReader) -> FeaturedStickers? {
            return Api.messages.FeaturedStickers.featuredStickersNotModified
        }
        static func parse_featuredStickers(_ reader: BufferReader) -> FeaturedStickers? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.StickerSetCovered]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.StickerSetCovered.self)
            }
            var _3: [Int64]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 570911930, elementType: Int64.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.messages.FeaturedStickers.featuredStickers(hash: _1!, sets: _2!, unread: _3!)
            }
            else {
                return nil
            }
        }
    
    }
    public enum Dialogs {
        case dialogs(dialogs: [Api.Dialog], messages: [Api.Message], chats: [Api.Chat], users: [Api.User])
        case dialogsSlice(count: Int32, dialogs: [Api.Dialog], messages: [Api.Message], chats: [Api.Chat], users: [Api.User])
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .dialogs(let dialogs, let messages, let chats, let users):
                    if boxed {
                        buffer.appendInt32(364538944)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(dialogs.count))
                    for item in dialogs {
                        item.serialize(buffer, true)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(messages.count))
                    for item in messages {
                        item.serialize(buffer, true)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(chats.count))
                    for item in chats {
                        item.serialize(buffer, true)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(users.count))
                    for item in users {
                        item.serialize(buffer, true)
                    }
                    break
                case .dialogsSlice(let count, let dialogs, let messages, let chats, let users):
                    if boxed {
                        buffer.appendInt32(1910543603)
                    }
                    serializeInt32(count, buffer: buffer, boxed: false)
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(dialogs.count))
                    for item in dialogs {
                        item.serialize(buffer, true)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(messages.count))
                    for item in messages {
                        item.serialize(buffer, true)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(chats.count))
                    for item in chats {
                        item.serialize(buffer, true)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(users.count))
                    for item in users {
                        item.serialize(buffer, true)
                    }
                    break
    }
    }
    
        static func parse_dialogs(_ reader: BufferReader) -> Dialogs? {
            var _1: [Api.Dialog]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Dialog.self)
            }
            var _2: [Api.Message]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Message.self)
            }
            var _3: [Api.Chat]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Chat.self)
            }
            var _4: [Api.User]?
            if let _ = reader.readInt32() {
                _4 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.messages.Dialogs.dialogs(dialogs: _1!, messages: _2!, chats: _3!, users: _4!)
            }
            else {
                return nil
            }
        }
        static func parse_dialogsSlice(_ reader: BufferReader) -> Dialogs? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.Dialog]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Dialog.self)
            }
            var _3: [Api.Message]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Message.self)
            }
            var _4: [Api.Chat]?
            if let _ = reader.readInt32() {
                _4 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Chat.self)
            }
            var _5: [Api.User]?
            if let _ = reader.readInt32() {
                _5 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 {
                return Api.messages.Dialogs.dialogsSlice(count: _1!, dialogs: _2!, messages: _3!, chats: _4!, users: _5!)
            }
            else {
                return nil
            }
        }
    
    }
    public enum FavedStickers {
        case favedStickersNotModified
        case favedStickers(hash: Int32, packs: [Api.StickerPack], stickers: [Api.Document])
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .favedStickersNotModified:
                    if boxed {
                        buffer.appendInt32(-1634752813)
                    }
                    
                    break
                case .favedStickers(let hash, let packs, let stickers):
                    if boxed {
                        buffer.appendInt32(-209768682)
                    }
                    serializeInt32(hash, buffer: buffer, boxed: false)
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(packs.count))
                    for item in packs {
                        item.serialize(buffer, true)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(stickers.count))
                    for item in stickers {
                        item.serialize(buffer, true)
                    }
                    break
    }
    }
    
        static func parse_favedStickersNotModified(_ reader: BufferReader) -> FavedStickers? {
            return Api.messages.FavedStickers.favedStickersNotModified
        }
        static func parse_favedStickers(_ reader: BufferReader) -> FavedStickers? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.StickerPack]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.StickerPack.self)
            }
            var _3: [Api.Document]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Document.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.messages.FavedStickers.favedStickers(hash: _1!, packs: _2!, stickers: _3!)
            }
            else {
                return nil
            }
        }
    
    }
    public enum AllStickers {
        case allStickersNotModified
        case allStickers(hash: Int32, sets: [Api.StickerSet])
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .allStickersNotModified:
                    if boxed {
                        buffer.appendInt32(-395967805)
                    }
                    
                    break
                case .allStickers(let hash, let sets):
                    if boxed {
                        buffer.appendInt32(-302170017)
                    }
                    serializeInt32(hash, buffer: buffer, boxed: false)
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(sets.count))
                    for item in sets {
                        item.serialize(buffer, true)
                    }
                    break
    }
    }
    
        static func parse_allStickersNotModified(_ reader: BufferReader) -> AllStickers? {
            return Api.messages.AllStickers.allStickersNotModified
        }
        static func parse_allStickers(_ reader: BufferReader) -> AllStickers? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.StickerSet]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.StickerSet.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.messages.AllStickers.allStickers(hash: _1!, sets: _2!)
            }
            else {
                return nil
            }
        }
    
    }
    public enum HighScores {
        case highScores(scores: [Api.HighScore], users: [Api.User])
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .highScores(let scores, let users):
                    if boxed {
                        buffer.appendInt32(-1707344487)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(scores.count))
                    for item in scores {
                        item.serialize(buffer, true)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(users.count))
                    for item in users {
                        item.serialize(buffer, true)
                    }
                    break
    }
    }
    
        static func parse_highScores(_ reader: BufferReader) -> HighScores? {
            var _1: [Api.HighScore]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.HighScore.self)
            }
            var _2: [Api.User]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.messages.HighScores.highScores(scores: _1!, users: _2!)
            }
            else {
                return nil
            }
        }
    
    }
}
}
