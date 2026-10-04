import 'package:flutter/material.dart';
import 'package:qrcode_generator/core/constants/app_colors.dart';
import 'package:qrcode_generator/core/models/qr_type.dart';

class QrTemplate {
  final String id;
  final String title;
  final String category;
  final String description;
  final QrType type;
  final IconData icon;
  final Color color;
  final Map<String, dynamic> initialValues;

  const QrTemplate({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.type,
    required this.icon,
    required this.color,
    required this.initialValues,
  });

  static List<QrTemplate> get builtInTemplates => const [
        // 1. Website
        QrTemplate(
          id: 'tpl_website',
          title: 'Personal Portfolio',
          category: 'Web & Digital',
          description: 'Share your personal website, portfolio, or resume link.',
          type: QrType.url,
          icon: Icons.language_rounded,
          color: AppColors.typeUrl,
          initialValues: {
            'url': 'https://myportfolio.dev',
          },
        ),
        // 2. Wi-Fi
        QrTemplate(
          id: 'tpl_wifi_guest',
          title: 'Guest Wi-Fi Network',
          category: 'Connectivity',
          description: 'Instant tap-free connection for office or home guests.',
          type: QrType.wifi,
          icon: Icons.wifi_rounded,
          color: AppColors.typeWifi,
          initialValues: {
            'ssid': 'Guest-HighSpeed-WiFi',
            'security': 'WPA',
            'hidden': false,
          },
        ),
        // 3. Contact Card
        QrTemplate(
          id: 'tpl_vcard_business',
          title: 'Executive Business Card',
          category: 'Networking',
          description: 'Share comprehensive vCard contact with title & company.',
          type: QrType.contact,
          icon: Icons.badge_rounded,
          color: AppColors.typeContact,
          initialValues: {
            'firstName': 'Alex',
            'lastName': 'Morgan',
            'company': 'Nexus Technologies Inc.',
            'phone': '+1 (555) 234-5678',
            'email': 'alex.morgan@nexustech.io',
            'website': 'https://nexustech.io',
            'address': '742 Evergreen Terrace, San Francisco, CA',
          },
        ),
        // 4. Email
        QrTemplate(
          id: 'tpl_email_support',
          title: 'Customer Support Request',
          category: 'Communication',
          description: 'Pre-filled email subject and body for immediate support tickets.',
          type: QrType.email,
          icon: Icons.support_agent_rounded,
          color: AppColors.typeEmail,
          initialValues: {
            'email': 'support@mybrand.com',
            'subject': 'Help Request: [Describe Issue]',
            'body': 'Hello Support Team,\n\nI need assistance with:\n- Device / Order ID:\n- Description of issue:\n\nThank you!',
          },
        ),
        // 5. Phone
        QrTemplate(
          id: 'tpl_phone_hotline',
          title: 'Direct Toll-Free Line',
          category: 'Communication',
          description: 'Instant one-tap phone dialing for reservations or helpdesk.',
          type: QrType.phone,
          icon: Icons.phone_in_talk_rounded,
          color: AppColors.typePhone,
          initialValues: {
            'phone': '+1-800-555-0199',
          },
        ),
        // 6. SMS
        QrTemplate(
          id: 'tpl_sms_rsvp',
          title: 'Quick RSVP Confirmation',
          category: 'Communication',
          description: 'Send pre-formatted confirmation message for events & bookings.',
          type: QrType.sms,
          icon: Icons.mark_email_read_rounded,
          color: AppColors.typeSms,
          initialValues: {
            'phone': '+15559876543',
            'message': 'RSVP YES: I will attend the upcoming annual conference.',
          },
        ),
        // 7. Social Profile - Instagram
        QrTemplate(
          id: 'tpl_social_instagram',
          title: 'Instagram Creator Profile',
          category: 'Social Media',
          description: 'Direct followers straight to your Instagram feed or profile.',
          type: QrType.social,
          icon: Icons.camera_alt_rounded,
          color: Color(0xFFE1306C),
          initialValues: {
            'platform': 'Instagram',
            'url': 'https://instagram.com/qrstudiopro',
          },
        ),
        // 8. Social Profile - LinkedIn
        QrTemplate(
          id: 'tpl_social_linkedin',
          title: 'LinkedIn Professional Profile',
          category: 'Social Media',
          description: 'Connect with clients, recruiters, and peers on LinkedIn.',
          type: QrType.social,
          icon: Icons.business_center_rounded,
          color: Color(0xFF0A66C2),
          initialValues: {
            'platform': 'LinkedIn',
            'url': 'https://linkedin.com/in/professional',
          },
        ),
        // 9. Business Information
        QrTemplate(
          id: 'tpl_biz_info',
          title: 'Business Info & Hours',
          category: 'Business',
          description: 'Text summary of operating hours, services, and location.',
          type: QrType.text,
          icon: Icons.storefront_rounded,
          color: Color(0xFF0D9488),
          initialValues: {
            'text': 'Studio Pro Services & Co.\nOpen Mon-Fri: 9:00 AM - 6:00 PM\nSat: 10:00 AM - 4:00 PM\nSunday: Closed\nCall +1 (555) 012-3456 for appointments.',
          },
        ),
        // 10. Location / Map URL
        QrTemplate(
          id: 'tpl_location_office',
          title: 'Office Headquarters Map',
          category: 'Navigation',
          description: 'Navigate visitors directly to your venue or headquarters.',
          type: QrType.location,
          icon: Icons.pin_drop_rounded,
          color: AppColors.typeLocation,
          initialValues: {
            'name': 'Silicon Valley Campus',
            'latitude': '37.4220',
            'longitude': '-122.0841',
          },
        ),
      ];
}
