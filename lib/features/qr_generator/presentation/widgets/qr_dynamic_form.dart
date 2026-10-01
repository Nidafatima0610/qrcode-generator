import 'package:flutter/material.dart';
import 'package:qr_code_generator/core/theme/app_theme.dart';
import 'package:qr_code_generator/features/qr_generator/controllers/qr_generator_controller.dart';
import 'package:qr_code_generator/features/qr_generator/models/qr_payload_type.dart';

/// Renders tailored input fields based on the selected [QrPayloadType].
class QrDynamicForm extends StatelessWidget {
  final QrGeneratorController controller;

  const QrDynamicForm({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    switch (controller.payloadType) {
      case QrPayloadType.text:
        return _buildTextForm(context);
      case QrPayloadType.url:
        return _buildUrlForm(context);
      case QrPayloadType.wifi:
        return _buildWifiForm(context);
      case QrPayloadType.email:
        return _buildEmailForm(context);
      case QrPayloadType.phone:
        return _buildPhoneForm(context);
      case QrPayloadType.sms:
        return _buildSmsForm(context);
      case QrPayloadType.contact:
        return _buildContactForm(context);
    }
  }

  // ==================== 1. Text Form ====================
  Widget _buildTextForm(BuildContext context) {
    return TextField(
      controller: controller.textController,
      keyboardType: TextInputType.multiline,
      minLines: 3,
      maxLines: 6,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => controller.generateQr(),
      decoration: InputDecoration(
        hintText: 'Enter text, notes, or long messages to encode...',
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 14, right: 10, top: 14),
          child: Align(
            alignment: Alignment.topCenter,
            widthFactor: 1.0,
            heightFactor: 1.0,
            child: Icon(Icons.text_fields_rounded, size: 20, color: AppTheme.primaryColor),
          ),
        ),
        suffixIcon: controller.textController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () => controller.textController.clear(),
              )
            : null,
      ),
    );
  }

  // ==================== 2. Website / URL Form ====================
  Widget _buildUrlForm(BuildContext context) {
    return TextField(
      controller: controller.urlController,
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => controller.generateQr(),
      decoration: InputDecoration(
        hintText: 'https://example.com or website.com',
        prefixIcon: const Icon(Icons.language_rounded, color: AppTheme.primaryColor),
        suffixIcon: controller.urlController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () => controller.urlController.clear(),
              )
            : null,
      ),
    );
  }

  // ==================== 3. Wi-Fi Form ====================
  Widget _buildWifiForm(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SSID
        TextField(
          controller: controller.wifiSsidController,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Network Name (SSID) *',
            hintText: 'e.g. Home_Network_5G',
            prefixIcon: const Icon(Icons.wifi_rounded, color: AppTheme.primaryColor),
            suffixIcon: controller.wifiSsidController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () => controller.wifiSsidController.clear(),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),

        // Security Selector
        Row(
          children: [
            Text(
              'Security:',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(width: 8),
            _buildSecurityChip('WPA/WPA2', isDark),
            const SizedBox(width: 6),
            _buildSecurityChip('WEP', isDark),
            const SizedBox(width: 6),
            _buildSecurityChip('None', isDark),
          ],
        ),
        const SizedBox(height: 12),

        // Password (if not None)
        if (controller.wifiSecurity != 'None') ...[
          TextField(
            controller: controller.wifiPasswordController,
            obscureText: controller.wifiObscurePassword,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => controller.generateQr(),
            decoration: InputDecoration(
              labelText: 'Wi-Fi Password *',
              hintText: 'Enter network password',
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryColor),
              suffixIcon: IconButton(
                icon: Icon(
                  controller.wifiObscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () => controller.toggleWifiObscurePassword(),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Hidden Network Toggle
        Row(
          children: [
            Checkbox(
              value: controller.wifiIsHidden,
              activeColor: AppTheme.primaryColor,
              onChanged: (val) => controller.toggleWifiHidden(val ?? false),
            ),
            const Expanded(
              child: Text(
                'Hidden Network (SSID is not broadcasting)',
                style: TextStyle(fontSize: 12.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecurityChip(String label, bool isDark) {
    final isSelected = controller.wifiSecurity == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => controller.setWifiSecurity(label),
      selectedColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppTheme.textPrimaryLight),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      showCheckmark: false,
    );
  }

  // ==================== 4. Email Form ====================
  Widget _buildEmailForm(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller.emailAddressController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Recipient Email *',
            hintText: 'alex@example.com',
            prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppTheme.primaryColor),
            suffixIcon: controller.emailAddressController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () => controller.emailAddressController.clear(),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller.emailSubjectController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Subject (Optional)',
            hintText: 'e.g. Project Inquiry',
            prefixIcon: Icon(Icons.subject_rounded, color: AppTheme.primaryColor),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller.emailBodyController,
          keyboardType: TextInputType.multiline,
          minLines: 2,
          maxLines: 4,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => controller.generateQr(),
          decoration: const InputDecoration(
            labelText: 'Message Body (Optional)',
            hintText: 'Write your message here...',
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 14, right: 10, top: 14),
              child: Align(
                alignment: Alignment.topCenter,
                widthFactor: 1.0,
                heightFactor: 1.0,
                child: Icon(Icons.message_outlined, size: 20, color: AppTheme.primaryColor),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== 5. Phone Form ====================
  Widget _buildPhoneForm(BuildContext context) {
    return TextField(
      controller: controller.phoneController,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => controller.generateQr(),
      decoration: InputDecoration(
        labelText: 'Phone Number *',
        hintText: '+1 234 567 8900',
        prefixIcon: const Icon(Icons.phone_rounded, color: AppTheme.primaryColor),
        helperText: 'Include country code prefix (e.g. +1, +44, +92)',
        suffixIcon: controller.phoneController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () => controller.phoneController.clear(),
              )
            : null,
      ),
    );
  }

  // ==================== 6. SMS Form ====================
  Widget _buildSmsForm(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller.smsPhoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Recipient Phone Number *',
            hintText: '+1 234 567 8900',
            prefixIcon: const Icon(Icons.phone_rounded, color: AppTheme.primaryColor),
            suffixIcon: controller.smsPhoneController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () => controller.smsPhoneController.clear(),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller.smsMessageController,
          keyboardType: TextInputType.multiline,
          minLines: 2,
          maxLines: 4,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => controller.generateQr(),
          decoration: const InputDecoration(
            labelText: 'SMS Message *',
            hintText: 'Enter text message to draft...',
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 14, right: 10, top: 14),
              child: Align(
                alignment: Alignment.topCenter,
                widthFactor: 1.0,
                heightFactor: 1.0,
                child: Icon(Icons.sms_rounded, size: 20, color: AppTheme.primaryColor),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== 7. Contact (vCard) Form ====================
  Widget _buildContactForm(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller.contactNameController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Full Name *',
            hintText: 'Jane Doe',
            prefixIcon: const Icon(Icons.person_rounded, color: AppTheme.primaryColor),
            suffixIcon: controller.contactNameController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () => controller.contactNameController.clear(),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller.contactPhoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: '+1 234 567 8900',
            prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primaryColor),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller.contactEmailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'jane@company.com',
            prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryColor),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller.contactOrgController,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => controller.generateQr(),
          decoration: const InputDecoration(
            labelText: 'Organization / Company (Optional)',
            hintText: 'Acme Corporation',
            prefixIcon: Icon(Icons.business_rounded, color: AppTheme.primaryColor),
          ),
        ),
      ],
    );
  }
}
