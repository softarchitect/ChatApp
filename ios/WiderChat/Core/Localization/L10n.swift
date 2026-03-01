import Foundation

enum TextKey {
    case appName, appTagline
    case loginTitle, loginSubtitle, emailLabel, emailPlaceholder, passwordLabel, passwordPlaceholder
    case loginButton, forgotPassword, loginError
    case chats, settings, conversationsTitle, searchPlaceholder, all, open, closed, unread
    case noConversations, noConversationsDesc
    case typeMessage, send, internalNote, internalNotePlaceholder, addNote
    case closeConversation, reopenConversation, conversationClosed
    case online, lastSeen
    case privacyPolicy, termsOfService, version
    case logout, logoutConfirm, cancel, confirm
    case pushNotifications, soundAlerts, darkMode, language, english, arabic
    case account, appearance, notificationSettings, about
    case today
    case newConversationTitle, newConversationMessage, nameLabel, phoneLabel, create
    case camera, gallery, document, audio, stopSendVoice
    case contactInfo, status, presence, mediaLinksDocs, mute, unmute, delete
    case mediaLinksDocsTitle, close, noItemsInTab
    case photo, video, link, unavailable, noUrlFromBackend, unableToLoadAudio
    case mediaTab, docsTab, linksTab
    case tapToOpenImage, openAction, failedToLoadImage, audioMessage, mediaMessage
    case location
    case internalNoteBadge, youLabel
    case assignAgent, unassignAgent, muteConversation, unmuteConversation
    case markAsRead, markAsUnread, attachDetachTag, sendTemplate, sendFlow, sendQuickReply, syncCustomField
    case updateContact
    case deleteChat
    case assignAgentTitle, agentId
    case attachDetachTagTitle, tagId, attach, detach
    case sendTemplateTitle, templateId
    case sendFlowTitle, flowId
    case sendQuickReplyTitle
    case syncCustomFieldTitle, fieldId, fieldValue, sync
    case deleteChatQuestion, deleteChatEndpointHint
    case callUnavailable, callUnavailableMessage, ok
    case lastUpdated
    case backendTools, profile, syncSupportData
    case createUpdateTag, tagName, tagColorHex, tagIdOptional, save
    case createUpdateReply, replyName, replyText, replyIdOptional
    case addContactTitle, emailOptional, add
    case searchContacts
}

func tr(_ locale: AppLocale, _ key: TextKey) -> String {
    let ar = locale == .ar
    switch key {
    case .appName: return ar ? "وايدرز" : "Widers"
    case .appTagline: return ar ? "واجهة واتساب للأعمال السحابية" : "WhatsApp Business Cloud API"
    case .loginTitle: return ar ? "مرحباً بعودتك" : "Welcome Back"
    case .loginSubtitle: return ar ? "سجّل الدخول لإدارة محادثاتك" : "Sign in to manage your conversations"
    case .emailLabel: return ar ? "البريد الإلكتروني" : "Email Address"
    case .emailPlaceholder: return ar ? "أدخل بريدك الإلكتروني" : "Enter your email"
    case .passwordLabel: return ar ? "كلمة المرور" : "Password"
    case .passwordPlaceholder: return ar ? "أدخل كلمة المرور" : "Enter your password"
    case .loginButton: return ar ? "تسجيل الدخول" : "Sign In"
    case .forgotPassword: return ar ? "نسيت كلمة المرور؟" : "Forgot password?"
    case .loginError: return ar ? "البريد الإلكتروني أو كلمة المرور غير صحيحة" : "Invalid email or password"
    case .chats: return ar ? "الدردشات" : "Chats"
    case .settings: return ar ? "الإعدادات" : "Settings"
    case .conversationsTitle: return ar ? "المحادثات" : "Conversations"
    case .searchPlaceholder: return ar ? "البحث في المحادثات..." : "Search conversations..."
    case .all: return ar ? "الكل" : "All"
    case .open: return ar ? "مفتوحة" : "Open"
    case .closed: return ar ? "مغلقة" : "Closed"
    case .unread: return ar ? "غير مقروءة" : "unread"
    case .noConversations: return ar ? "لا توجد محادثات بعد" : "No conversations yet"
    case .noConversationsDesc: return ar ? "عندما يراسلك العملاء، ستظهر المحادثات هنا." : "When customers message you, conversations will appear here."
    case .typeMessage: return ar ? "اكتب رسالة..." : "Type a message..."
    case .send: return ar ? "إرسال" : "Send"
    case .internalNote: return ar ? "ملاحظة داخلية" : "Internal Note"
    case .internalNotePlaceholder: return ar ? "اكتب ملاحظة (غير مرئية للعميل)..." : "Write a note (not visible to customer)..."
    case .addNote: return ar ? "إضافة ملاحظة" : "Add Note"
    case .closeConversation: return ar ? "إغلاق المحادثة" : "Close Conversation"
    case .reopenConversation: return ar ? "إعادة فتح المحادثة" : "Reopen Conversation"
    case .conversationClosed: return ar ? "تم إغلاق المحادثة" : "Conversation closed"
    case .online: return ar ? "متصل" : "Online"
    case .lastSeen: return ar ? "آخر ظهور" : "Last seen"
    case .privacyPolicy: return ar ? "سياسة الخصوصية" : "Privacy Policy"
    case .termsOfService: return ar ? "شروط الخدمة" : "Terms of Service"
    case .version: return ar ? "الإصدار" : "Version"
    case .logout: return ar ? "تسجيل الخروج" : "Sign Out"
    case .logoutConfirm: return ar ? "هل أنت متأكد أنك تريد تسجيل الخروج؟" : "Are you sure you want to sign out?"
    case .cancel: return ar ? "إلغاء" : "Cancel"
    case .confirm: return ar ? "تأكيد" : "Confirm"
    case .pushNotifications: return ar ? "إشعارات الدفع" : "Push Notifications"
    case .soundAlerts: return ar ? "التنبيهات الصوتية" : "Sound Alerts"
    case .darkMode: return ar ? "الوضع الداكن" : "Dark Mode"
    case .language: return ar ? "اللغة" : "Language"
    case .english: return ar ? "الإنجليزية" : "English"
    case .arabic: return ar ? "العربية" : "Arabic"
    case .account: return ar ? "الحساب" : "Account"
    case .appearance: return ar ? "المظهر" : "Appearance"
    case .notificationSettings: return ar ? "إعدادات الإشعارات" : "Notification Settings"
    case .about: return ar ? "حول" : "About"
    case .today: return ar ? "اليوم" : "Today"
    case .newConversationTitle: return ar ? "محادثة جديدة" : "New conversation"
    case .newConversationMessage: return ar ? "أنشئ جهة اتصال وافتح محادثتها." : "Create a contact and open its chat."
    case .nameLabel: return ar ? "الاسم" : "Name"
    case .phoneLabel: return ar ? "الهاتف" : "Phone"
    case .create: return ar ? "إنشاء" : "Create"
    case .camera: return ar ? "الكاميرا" : "Camera"
    case .gallery: return ar ? "المعرض" : "Gallery"
    case .document: return ar ? "مستند" : "Document"
    case .audio: return ar ? "صوت" : "Audio"
    case .stopSendVoice: return ar ? "إيقاف وإرسال الصوت" : "Stop & send voice"
    case .contactInfo: return ar ? "معلومات جهة الاتصال" : "Contact info"
    case .status: return ar ? "الحالة" : "Status"
    case .presence: return ar ? "التواجد" : "Presence"
    case .mediaLinksDocs: return ar ? "الوسائط والروابط والمستندات" : "Media, links and docs"
    case .mute: return ar ? "كتم" : "Mute"
    case .unmute: return ar ? "إلغاء الكتم" : "Unmute"
    case .delete: return ar ? "حذف" : "Delete"
    case .mediaLinksDocsTitle: return ar ? "الوسائط والروابط والمستندات" : "Media, links and docs"
    case .close: return ar ? "إغلاق" : "Close"
    case .noItemsInTab: return ar ? "لا توجد عناصر في هذا التبويب." : "No items in this tab."
    case .photo: return ar ? "صورة" : "Photo"
    case .video: return ar ? "فيديو" : "Video"
    case .link: return ar ? "رابط" : "Link"
    case .unavailable: return ar ? "غير متاح" : "Unavailable"
    case .noUrlFromBackend: return ar ? "لا يوجد رابط من الخادم" : "No URL from backend"
    case .unableToLoadAudio: return ar ? "تعذر تحميل الصوت." : "Unable to load audio."
    case .mediaTab: return ar ? "وسائط" : "Media"
    case .docsTab: return ar ? "مستندات" : "Docs"
    case .linksTab: return ar ? "روابط" : "Links"
    case .tapToOpenImage: return ar ? "اضغط لفتح الصورة" : "Tap to open image"
    case .openAction: return ar ? "فتح" : "Open"
    case .failedToLoadImage: return ar ? "تعذر تحميل الصورة" : "Failed to load image"
    case .audioMessage: return ar ? "رسالة صوتية" : "Audio message"
    case .mediaMessage: return ar ? "رسالة وسائط" : "Media message"
    case .location: return ar ? "موقع" : "Location"
    case .internalNoteBadge: return ar ? "ملاحظة داخلية" : "INTERNAL NOTE"
    case .youLabel: return ar ? "أنت" : "You"
    case .assignAgent: return ar ? "تعيين وكيل" : "Assign agent"
    case .unassignAgent: return ar ? "إلغاء تعيين الوكيل" : "Unassign agent"
    case .muteConversation: return ar ? "كتم المحادثة" : "Mute conversation"
    case .unmuteConversation: return ar ? "إلغاء كتم المحادثة" : "Unmute conversation"
    case .markAsRead: return ar ? "تحديد كمقروء" : "Mark as read"
    case .markAsUnread: return ar ? "تحديد كغير مقروء" : "Mark as unread"
    case .attachDetachTag: return ar ? "إرفاق / إزالة وسم" : "Attach / detach tag"
    case .sendTemplate: return ar ? "إرسال قالب" : "Send template"
    case .sendFlow: return ar ? "إرسال تدفق" : "Send flow"
    case .sendQuickReply: return ar ? "إرسال رد سريع" : "Send quick reply"
    case .syncCustomField: return ar ? "مزامنة حقل مخصص" : "Sync custom field"
    case .updateContact: return ar ? "تحديث جهة الاتصال" : "Update contact"
    case .deleteChat: return ar ? "حذف المحادثة" : "Delete chat"
    case .assignAgentTitle: return ar ? "تعيين وكيل" : "Assign agent"
    case .agentId: return ar ? "معرّف الوكيل" : "Agent ID"
    case .attachDetachTagTitle: return ar ? "إرفاق / إزالة وسم" : "Attach / detach tag"
    case .tagId: return ar ? "معرّف الوسم" : "Tag ID"
    case .attach: return ar ? "إرفاق" : "Attach"
    case .detach: return ar ? "إزالة" : "Detach"
    case .sendTemplateTitle: return ar ? "إرسال قالب" : "Send template"
    case .templateId: return ar ? "معرّف القالب" : "Template ID"
    case .sendFlowTitle: return ar ? "إرسال تدفق" : "Send flow"
    case .flowId: return ar ? "معرّف التدفق" : "Flow ID"
    case .sendQuickReplyTitle: return ar ? "إرسال رد سريع" : "Send quick reply"
    case .syncCustomFieldTitle: return ar ? "مزامنة حقل مخصص" : "Sync custom field"
    case .fieldId: return ar ? "معرّف الحقل" : "Field ID"
    case .fieldValue: return ar ? "قيمة الحقل" : "Field Value"
    case .sync: return ar ? "مزامنة" : "Sync"
    case .deleteChatQuestion: return ar ? "حذف المحادثة؟" : "Delete chat?"
    case .deleteChatEndpointHint: return ar ? "سيستدعي هذا إجراء حذف المحادثة لجهة الاتصال الحالية." : "This calls delete chat endpoint for this contact."
    case .callUnavailable: return ar ? "الاتصال غير متاح" : "Call unavailable"
    case .callUnavailableMessage: return ar ? "رقم الهاتف غير متاح لجهة الاتصال هذه." : "Phone number is unavailable for this contact."
    case .ok: return ar ? "حسنًا" : "OK"
    case .lastUpdated: return ar ? "آخر تحديث" : "LAST UPDATED"
    case .backendTools: return ar ? "أدوات الخادم" : "Backend tools"
    case .profile: return ar ? "الملف الشخصي" : "Profile"
    case .syncSupportData: return ar ? "مزامنة بيانات الدعم" : "Sync support data"
    case .createUpdateTag: return ar ? "إنشاء / تحديث وسم" : "Create / Update Tag"
    case .tagName: return ar ? "اسم الوسم" : "Tag name"
    case .tagColorHex: return ar ? "لون الوسم (#hex)" : "Tag color (#hex)"
    case .tagIdOptional: return ar ? "معرّف الوسم (اختياري)" : "Tag ID (optional)"
    case .save: return ar ? "حفظ" : "Save"
    case .createUpdateReply: return ar ? "إنشاء / تحديث رد" : "Create / Update Reply"
    case .replyName: return ar ? "اسم الرد" : "Reply name"
    case .replyText: return ar ? "نص الرد" : "Reply text"
    case .replyIdOptional: return ar ? "معرّف الرد (اختياري)" : "Reply ID (optional)"
    case .addContactTitle: return ar ? "إضافة جهة اتصال" : "Add Contact"
    case .emailOptional: return ar ? "البريد الإلكتروني (اختياري)" : "Email (optional)"
    case .add: return ar ? "إضافة" : "Add"
    case .searchContacts: return ar ? "البحث في جهات الاتصال" : "Search contacts"
    }
}
