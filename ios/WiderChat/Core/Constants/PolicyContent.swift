import Foundation

enum PolicyContent {
    static let privacySections: [PolicySectionData] = [
        .init(icon: "eye.fill", title: "Information We Collect", body: "We collect information you provide directly, including your name, email address, phone number, and business details when you register for an account. We also collect message content, conversation metadata, and usage analytics to provide and improve our services."),
        .init(icon: "internaldrive.fill", title: "How We Use Your Information", body: "We use the information we collect to operate, maintain, and provide platform features, including routing and managing WhatsApp Business messages, enabling team collaboration through internal notes, and sending service-related notifications."),
        .init(icon: "lock.fill", title: "Data Storage & Security", body: "Your data is stored on secure servers with encryption at rest and in transit. We implement role-based access controls, regular security checks, and automated threat detection."),
        .init(icon: "globe", title: "WhatsApp & Meta Compliance", body: "As a Meta-approved WhatsApp Business Cloud API provider, we comply with Meta Platform Terms and WhatsApp Business policies."),
        .init(icon: "shield.fill", title: "Third-Party Services", body: "We may share data with trusted third-party providers who assist us in operating our platform under confidentiality agreements."),
        .init(icon: "checkmark.shield.fill", title: "Your Rights", body: "You can request access, correction, or deletion of your personal data by contacting support."),
        .init(icon: "envelope.fill", title: "Contact Us", body: "privacy@widers.com")
    ]

    static let termsSections: [PolicySectionData] = [
        .init(icon: "person.crop.circle.fill", title: "Account Registration", body: "To use Widers, you must register for a merchant account and provide accurate information. You are responsible for keeping account credentials secure."),
        .init(icon: "shield.fill", title: "Acceptable Use", body: "You agree to use the service only for lawful purposes and in compliance with WhatsApp Business policies. No spam, abuse, or impersonation."),
        .init(icon: "creditcard.fill", title: "Subscription & Billing", body: "Access to Widers is subscription-based. Plans are billed monthly or annually according to the selected package."),
        .init(icon: "clock.fill", title: "Service Level Agreement", body: "We strive to maintain high platform uptime. Scheduled maintenance windows will be communicated in advance."),
        .init(icon: "doc.text.fill", title: "Intellectual Property", body: "Widers platform design and features are protected. You retain ownership of your own customer content and messages."),
        .init(icon: "exclamationmark.triangle.fill", title: "Limitation of Liability", body: "To the maximum extent permitted by law, Widers is not liable for indirect or consequential damages."),
        .init(icon: "xmark.octagon.fill", title: "Termination", body: "Either party may terminate the service. Data retention and deletion policies apply as defined in the agreement."),
        .init(icon: "building.columns.fill", title: "Governing Law", body: "Any disputes are resolved according to applicable governing law and dispute-resolution terms.")
    ]

    static let versionFeatures: [String] = [
        "Real-time WhatsApp Business messaging",
        "Multi-agent conversation management",
        "Internal notes and team collaboration",
        "Conversation analytics and reporting",
        "Automated message routing and assignment",
        "Template message management"
    ]
}
