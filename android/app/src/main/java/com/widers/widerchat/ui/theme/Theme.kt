package com.widers.widerchat.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val DarkColorScheme = darkColorScheme(
    primary = GreenPrimaryDark,
    onPrimary = SurfaceLight,
    background = BgDark,
    onBackground = TextPrimaryDark,
    surface = SurfaceDark,
    onSurface = TextPrimaryDark,
    secondary = SecondaryDark,
    onSecondary = TextPrimaryDark,
    tertiary = GreenAccent,
    outline = BorderDark,
    surfaceVariant = SecondaryDark,
    onSurfaceVariant = TextMutedDark,
    error = androidx.compose.ui.graphics.Color(0xFFDC2626)
)

private val LightColorScheme = lightColorScheme(
    primary = GreenPrimary,
    onPrimary = SurfaceLight,
    background = BgLight,
    onBackground = TextPrimaryLight,
    surface = SurfaceLight,
    onSurface = TextPrimaryLight,
    secondary = SecondaryLight,
    onSecondary = TextPrimaryLight,
    tertiary = GreenAccent,
    outline = BorderLight,
    surfaceVariant = SecondaryLight,
    onSurfaceVariant = TextMutedLight,
    error = androidx.compose.ui.graphics.Color(0xFFEF4444)
)

@Composable
fun WiderChatTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = false,
    content: @Composable () -> Unit
) {
    val colors = if (darkTheme) DarkColorScheme else LightColorScheme
    MaterialTheme(colorScheme = colors, typography = Typography, content = content)
}