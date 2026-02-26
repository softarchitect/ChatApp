package com.widers.widerchat.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.Email
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.Public
import androidx.compose.material.icons.outlined.Security
import androidx.compose.material.icons.outlined.Shield
import androidx.compose.material.icons.outlined.Storage
import androidx.compose.material.icons.outlined.Visibility
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.widers.widerchat.domain.model.AppLocale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PrivacyScreen(
    modifier: Modifier = Modifier,
    locale: AppLocale,
    onBack: () -> Unit
) {
    val sections = listOf(
        "Information We Collect" to "We collect information you provide directly, including your name, email address, phone number, and business details when you register for an account. We also collect message content, conversation metadata, and usage analytics to provide and improve our services.",
        "How We Use Your Information" to "We use the information we collect to operate, maintain, and provide platform features, including routing and managing WhatsApp Business messages, enabling team collaboration through internal notes, and sending service-related notifications.",
        "Data Storage & Security" to "Your data is stored on secure servers with encryption at rest and in transit. We implement role-based access controls, regular security checks, and automated threat detection.",
        "WhatsApp & Meta Compliance" to "As a Meta-approved WhatsApp Business Cloud API provider, we comply with Meta Platform Terms and WhatsApp Business policies.",
        "Third-Party Services" to "We may share data with trusted third-party providers who assist us in operating our platform under confidentiality agreements.",
        "Your Rights" to "You can request access, correction, or deletion of your personal data by contacting support.",
        "Contact Us" to "privacy@widers.com"
    )

    val iconList = listOf(
        Icons.Outlined.Visibility,
        Icons.Outlined.Storage,
        Icons.Outlined.Lock,
        Icons.Outlined.Public,
        Icons.Outlined.Security,
        Icons.Outlined.Shield,
        Icons.Outlined.Email
    )

    val title = if (locale == AppLocale.AR) "سياسة الخصوصية" else "Privacy Policy"

    Scaffold(
        modifier = modifier.fillMaxSize(),
        topBar = {
            TopAppBar(
                title = { Text(title, fontWeight = FontWeight.SemiBold) },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Outlined.ArrowBack, null) } }
            )
        }
    ) { pad ->
        LazyColumn(modifier = Modifier.padding(pad)) {
            item {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(MaterialTheme.colorScheme.secondary.copy(alpha = 0.35f))
                        .padding(horizontal = 20.dp, vertical = 14.dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        HorizontalDivider(modifier = Modifier.weight(1f), color = MaterialTheme.colorScheme.outline.copy(alpha = 0.4f))
                        Text(
                            "  LAST UPDATED  ",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        HorizontalDivider(modifier = Modifier.weight(1f), color = MaterialTheme.colorScheme.outline.copy(alpha = 0.4f))
                    }
                    Text(
                        "February 25, 2026",
                        modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                    Text(
                        "Widers is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our WhatsApp Business Cloud API platform and mobile application.",
                        modifier = Modifier.padding(top = 12.dp),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            itemsIndexed(sections) { idx, section ->
                Card(
                    modifier = Modifier
                        .padding(horizontal = 16.dp, vertical = 8.dp)
                        .fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Card(
                                shape = RoundedCornerShape(20.dp),
                                colors = CardDefaults.cardColors(containerColor = Color(0xFF10B981).copy(alpha = 0.1f))
                            ) {
                                Icon(iconList[idx], null, modifier = Modifier.padding(8.dp), tint = Color(0xFF10B981))
                            }
                            Text(
                                section.first,
                                modifier = Modifier.weight(1f).padding(start = 10.dp),
                                fontWeight = FontWeight.SemiBold
                            )
                            Text(
                                "${idx + 1}".padStart(2, '0'),
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        Text(
                            section.second,
                            modifier = Modifier.padding(top = 8.dp),
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }
}
