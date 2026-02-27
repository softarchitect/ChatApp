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
    }
}
