import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:qrcode_generator/core/constants/app_colors.dart';
import 'package:qrcode_generator/core/models/qr_customization.dart';
import 'package:qrcode_generator/core/models/qr_item.dart';
import 'package:qrcode_generator/core/models/qr_type.dart';
import 'package:qrcode_generator/core/services/qr_payload_builder.dart';
import 'package:qrcode_generator/core/services/storage_service.dart';
import 'package:qrcode_generator/presentation/widgets/custom_text_field.dart';
import 'package:qrcode_generator/presentation/screens/preview/qr_preview_screen.dart';

class CreateScreen extends StatefulWidget {
  final StorageService storageService;
  final QrType initialType;

  const CreateScreen({
    super.key,
    required this.storageService,
    this.initialType = QrType.url,
  });

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _formKey = GlobalKey<FormState>();
  late QrType _selectedType;

  // Customization
  int _selectedColorPresetIndex = 0;
  String _selectedErrorCorrection = 'M';
  final double _qrSize = 240.0;
  bool _showCustomization = false;

  // Controllers for Text
  final _textController = TextEditingController();

  // Controllers for URL
  final _urlController = TextEditingController(text: 'https://');

  // Controllers for Wi-Fi
  final _wifiSsidController = TextEditingController();
  final _wifiPasswordController = TextEditingController();
  String _wifiSecurity = 'WPA';
  bool _wifiHidden = false;
  bool _wifiObscurePass = true;

  // Controllers for Contact
  final _contactFirstNameController = TextEditingController();
  final _contactLastNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactOrgController = TextEditingController();
  final _contactAddressController = TextEditingController();
  final _contactWebsiteController = TextEditingController();

  // Controllers for Email
  final _emailRecipientController = TextEditingController();
  final _emailSubjectController = TextEditingController();
  final _emailBodyController = TextEditingController();

  // Controllers for Phone
  final _phoneController = TextEditingController();

  // Controllers for SMS
  final _smsPhoneController = TextEditingController();
  final _smsMessageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  void didUpdateWidget(covariant CreateScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialType != widget.initialType) {
      setState(() {
        _selectedType = widget.initialType;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _urlController.dispose();
    _wifiSsidController.dispose();
    _wifiPasswordController.dispose();
    _contactFirstNameController.dispose();
    _contactLastNameController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _contactOrgController.dispose();
    _contactAddressController.dispose();
    _contactWebsiteController.dispose();
    _emailRecipientController.dispose();
    _emailSubjectController.dispose();
    _emailBodyController.dispose();
    _phoneController.dispose();
    _smsPhoneController.dispose();
    _smsMessageController.dispose();
    super.dispose();
  }

  QrCustomization get _currentCustomization {
    final preset = AppColors.presets[_selectedColorPresetIndex];
    return QrCustomization(
      foregroundColor: preset.foreground,
      backgroundColor: preset.background,
      size: _qrSize,
      errorCorrectionLevel: _selectedErrorCorrection,
    );
  }

  String _buildPayload() {
    switch (_selectedType) {
      case QrType.text:
        return QrPayloadBuilder.buildText(_textController.text);
      case QrType.url:
        return QrPayloadBuilder.buildUrl(_urlController.text);
      case QrType.wifi:
        return QrPayloadBuilder.buildWifi(
          ssid: _wifiSsidController.text,
          password: _wifiPasswordController.text,
          security: _wifiSecurity,
          hidden: _wifiHidden,
        );
      case QrType.contact:
        return QrPayloadBuilder.buildContact(
          firstName: _contactFirstNameController.text,
          lastName: _contactLastNameController.text,
          phone: _contactPhoneController.text,
          email: _contactEmailController.text,
          company: _contactOrgController.text,
          address: _contactAddressController.text,
          website: _contactWebsiteController.text,
        );
      case QrType.email:
        return QrPayloadBuilder.buildEmail(
          email: _emailRecipientController.text,
          subject: _emailSubjectController.text,
          body: _emailBodyController.text,
        );
      case QrType.phone:
        return QrPayloadBuilder.buildPhone(_phoneController.text);
      case QrType.sms:
        return QrPayloadBuilder.buildSms(
          phone: _smsPhoneController.text,
          message: _smsMessageController.text,
        );
    }
  }

  String _buildTitle() {
    switch (_selectedType) {
      case QrType.text:
        final t = _textController.text.trim();
        return t.length > 25 ? '${t.substring(0, 25)}...' : t;
      case QrType.url:
        return _urlController.text.trim();
      case QrType.wifi:
        return 'Wi-Fi: ${_wifiSsidController.text.trim()}';
      case QrType.contact:
        final name =
            '${_contactFirstNameController.text.trim()} ${_contactLastNameController.text.trim()}'
                .trim();
        return name.isNotEmpty ? name : 'New Contact';
      case QrType.email:
        return 'Email: ${_emailRecipientController.text.trim()}';
      case QrType.phone:
        return 'Call ${_phoneController.text.trim()}';
      case QrType.sms:
        return 'SMS to ${_smsPhoneController.text.trim()}';
    }
  }

  String _buildSubtitle() {
    switch (_selectedType) {
      case QrType.text:
        return 'Plain Text Note';
      case QrType.url:
        return 'Website Link';
      case QrType.wifi:
        return 'Security: $_wifiSecurity';
      case QrType.contact:
        return _contactPhoneController.text.isNotEmpty
            ? _contactPhoneController.text.trim()
            : _contactEmailController.text.trim();
      case QrType.email:
        return _emailSubjectController.text.trim();
      case QrType.phone:
        return 'Telephone Number';
      case QrType.sms:
        return _smsMessageController.text.trim();
    }
  }

  void _generateQrCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final payload = _buildPayload();
    final title = _buildTitle();
    final subtitle = _buildSubtitle();

    final newItem = QrItem(
      id: const Uuid().v4(),
      type: _selectedType,
      title: title,
      subtitle: subtitle,
      rawPayload: payload,
      createdAt: DateTime.now(),
      customization: _currentCustomization,
    );

    // Save automatically to persistent history
    await widget.storageService.saveItem(newItem);

    if (!mounted) return;

    // Navigate to polished preview screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QrPreviewScreen(
          item: newItem,
          storageService: widget.storageService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create QR Code'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            children: [
              // 1. QR Type Selection Title
              Text(
                'Select QR Type',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
              ),
              const SizedBox(height: 12),

              // Horizontal Type Selection Cards
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: QrType.values.length,
                  separatorBuilder: (_, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final type = QrType.values[index];
                    final isSelected = type == _selectedType;
                    final typeColor = type.color;

                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        setState(() {
                          _selectedType = type;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 82,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? typeColor.withValues(alpha: isDark ? 0.25 : 0.12)
                              : (isDark ? AppColors.darkCard : Colors.white),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? typeColor
                                : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: typeColor.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                type.icon,
                                size: 20,
                                color: typeColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              type.shortName,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? typeColor
                                    : (isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Description banner of selected type
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedType.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _selectedType.color.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedType.icon,
                      size: 18,
                      color: _selectedType.color,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedType.description,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Dynamic Input Form
              _buildTypeForm(),
              const SizedBox(height: 24),

              // 3. QR Customization Accordion
              Card(
                child: ExpansionTile(
                  initiallyExpanded: _showCustomization,
                  onExpansionChanged: (val) {
                    setState(() => _showCustomization = val);
                  },
                  shape: const Border(),
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.palette_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'QR Style & Customization',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Preset colors, error correction, & size',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const SizedBox(height: 12),

                          // Color Palette Presets
                          const Text(
                            'Color Palette',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 60,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: AppColors.presets.length,
                              separatorBuilder: (_, index) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final p = AppColors.presets[index];
                                final isSelected =
                                    index == _selectedColorPresetIndex;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedColorPresetIndex = index;
                                    });
                                  },
                                  child: Container(
                                    width: 78,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkSurface
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.grey.shade300,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: p.background,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.grey.shade400,
                                                width: 1),
                                          ),
                                          child: Center(
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: p.foreground,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          p.name.split(' ').first,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Error Correction Level
                          const Text(
                            'Error Correction Level',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Higher levels preserve readability even if QR is slightly damaged or printed on uneven surfaces.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _ecChoiceChip('L', 'Low (7%)'),
                              const SizedBox(width: 8),
                              _ecChoiceChip('M', 'Med (15%)'),
                              const SizedBox(width: 8),
                              _ecChoiceChip('Q', 'Qrt (25%)'),
                              const SizedBox(width: 8),
                              _ecChoiceChip('H', 'High (30%)'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Generate Button
              ElevatedButton.icon(
                onPressed: _generateQrCode,
                icon: const Icon(Icons.qr_code_rounded, size: 22),
                label: const Text('Generate & Preview QR'),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ecChoiceChip(String level, String label) {
    final isSelected = _selectedErrorCorrection == level;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _selectedErrorCorrection = level),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: Column(
            children: [
              Text(
                level,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : null,
                ),
              ),
              Text(
                label.split(' ').first,
                style: TextStyle(
                  fontSize: 9.5,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.85)
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeForm() {
    switch (_selectedType) {
      case QrType.text:
        return _buildTextForm();
      case QrType.url:
        return _buildUrlForm();
      case QrType.wifi:
        return _buildWifiForm();
      case QrType.contact:
        return _buildContactForm();
      case QrType.email:
        return _buildEmailForm();
      case QrType.phone:
        return _buildPhoneForm();
      case QrType.sms:
        return _buildSmsForm();
    }
  }

  // 1. Text Form
  Widget _buildTextForm() {
    return Column(
      children: [
        CustomTextField(
          controller: _textController,
          label: 'Plain Text or Note',
          hint: 'Enter any message, notes, passwords, or text...',
          prefixIcon: Icons.notes_rounded,
          maxLines: 4,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Please enter some text';
            }
            return null;
          },
        ),
      ],
    );
  }

  // 2. URL Form
  Widget _buildUrlForm() {
    return Column(
      children: [
        CustomTextField(
          controller: _urlController,
          label: 'Website Address',
          hint: 'https://example.com',
          prefixIcon: Icons.link_rounded,
          keyboardType: TextInputType.url,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Please enter a URL';
            }
            final trimmed = v.trim();
            if (trimmed == 'https://' || trimmed == 'http://') {
              return 'Please enter a valid domain address';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        // Quick URL Domain Extension chips
        Row(
          children: [
            const Text(
              'Quick Add:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            _domainChip('.com'),
            const SizedBox(width: 6),
            _domainChip('.org'),
            const SizedBox(width: 6),
            _domainChip('.io'),
            const SizedBox(width: 6),
            _domainChip('.app'),
          ],
        ),
      ],
    );
  }

  Widget _domainChip(String extension) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {
        setState(() {
          _urlController.text = '${_urlController.text}$extension';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          extension,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  // 3. Wi-Fi Form
  Widget _buildWifiForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        CustomTextField(
          controller: _wifiSsidController,
          label: 'Network Name (SSID)',
          hint: 'e.g. Home_WiFi_5G',
          prefixIcon: Icons.wifi_rounded,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Please enter Wi-Fi network name';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),

        // Security Selector
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Type',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _wifiSecurity,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.security_rounded, size: 20),
              ),
              items: const [
                DropdownMenuItem(value: 'WPA', child: Text('WPA / WPA2 / WPA3 (Recommended)')),
                DropdownMenuItem(value: 'WEP', child: Text('WEP')),
                DropdownMenuItem(value: 'nopass', child: Text('None (Open Network)')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _wifiSecurity = val);
                }
              },
            ),
          ],
        ),

        if (_wifiSecurity != 'nopass') ...[
          const SizedBox(height: 14),
          CustomTextField(
            controller: _wifiPasswordController,
            label: 'Network Password',
            hint: 'Enter Wi-Fi password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _wifiObscurePass,
            suffixIcon: IconButton(
              icon: Icon(
                _wifiObscurePass
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _wifiObscurePass = !_wifiObscurePass),
            ),
            validator: (v) {
              if (_wifiSecurity != 'nopass' && (v == null || v.isEmpty)) {
                return 'Password is required for secured network';
              }
              return null;
            },
          ),
        ],

        const SizedBox(height: 14),
        // Hidden Network Switch
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.visibility_off_rounded, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Hidden Network',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Switch(
                value: _wifiHidden,
                activeThumbColor: AppColors.primary,
                onChanged: (val) => setState(() => _wifiHidden = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 4. Contact / vCard Form
  Widget _buildContactForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _contactFirstNameController,
                label: 'First Name',
                hint: 'John',
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: _contactLastNameController,
                label: 'Last Name',
                hint: 'Doe',
                prefixIcon: Icons.person_outline_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: _contactPhoneController,
          label: 'Phone Number',
          hint: '+1 234 567 8900',
          prefixIcon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Phone number is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: _contactEmailController,
          label: 'Email (Optional)',
          hint: 'john.doe@example.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: _contactOrgController,
          label: 'Company / Organization (Optional)',
          hint: 'Acme Corp',
          prefixIcon: Icons.business_rounded,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: _contactAddressController,
          label: 'Address (Optional)',
          hint: '123 Tech Avenue, Silicon Valley',
          prefixIcon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: _contactWebsiteController,
          label: 'Website (Optional)',
          hint: 'https://johndoe.me',
          prefixIcon: Icons.language_rounded,
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  // 5. Email Form
  Widget _buildEmailForm() {
    return Column(
      children: [
        CustomTextField(
          controller: _emailRecipientController,
          label: 'Recipient Email',
          hint: 'contact@company.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Please enter recipient email';
            }
            if (!v.contains('@') || !v.contains('.')) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: _emailSubjectController,
          label: 'Subject',
          hint: 'Meeting follow up / Inquiry',
          prefixIcon: Icons.subject_rounded,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: _emailBodyController,
          label: 'Message Body',
          hint: 'Hi, I would like to inquire about...',
          prefixIcon: Icons.message_outlined,
          maxLines: 4,
        ),
      ],
    );
  }

  // 6. Phone Form
  Widget _buildPhoneForm() {
    return Column(
      children: [
        CustomTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: '+1 555 123 4567',
          prefixIcon: Icons.phone_in_talk_rounded,
          keyboardType: TextInputType.phone,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Please enter a phone number';
            }
            if (v.trim().length < 3) {
              return 'Phone number is too short';
            }
            return null;
          },
        ),
      ],
    );
  }

  // 7. SMS Form
  Widget _buildSmsForm() {
    return Column(
      children: [
        CustomTextField(
          controller: _smsPhoneController,
          label: 'Recipient Phone Number',
          hint: '+1 555 987 6543',
          prefixIcon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Please enter phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: _smsMessageController,
          label: 'SMS Message',
          hint: 'Enter your message text...',
          prefixIcon: Icons.sms_outlined,
          maxLines: 3,
        ),
      ],
    );
  }
}
