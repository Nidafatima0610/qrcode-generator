import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:qrcode_generator/core/constants/app_colors.dart';
import 'package:qrcode_generator/core/models/qr_customization.dart';
import 'package:qrcode_generator/core/models/qr_item.dart';
import 'package:qrcode_generator/core/models/qr_preset.dart';
import 'package:qrcode_generator/core/models/qr_type.dart';
import 'package:qrcode_generator/core/services/qr_payload_builder.dart';
import 'package:qrcode_generator/core/services/storage_service.dart';
import 'package:qrcode_generator/presentation/screens/presets/presets_screen.dart';
import 'package:qrcode_generator/presentation/screens/preview/qr_preview_screen.dart';
import 'package:qrcode_generator/presentation/widgets/custom_text_field.dart';
import 'package:qrcode_generator/presentation/widgets/qr_render_view.dart';

class CreateScreen extends StatefulWidget {
  final StorageService storageService;
  final QrType initialType;
  final Map<String, dynamic>? initialValues;
  final QrItem? editingItem;

  const CreateScreen({
    super.key,
    required this.storageService,
    this.initialType = QrType.url,
    this.initialValues,
    this.editingItem,
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
  double _qrSize = 240.0;
  String _selectedEyeShape = 'square';
  String _selectedModuleShape = 'square';
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

  // Controllers for Location
  final _locationNameController = TextEditingController();
  final _locationLatController = TextEditingController();
  final _locationLngController = TextEditingController();

  // Controllers for Social Profile
  String _socialPlatform = 'Instagram';
  final _socialUrlController = TextEditingController();

  // Controllers for Business Card (vCard)
  final _bizCardFullNameController = TextEditingController();
  final _bizCardTitleController = TextEditingController();
  final _bizCardCompanyController = TextEditingController();
  final _bizCardPhoneController = TextEditingController();
  final _bizCardEmailController = TextEditingController();
  final _bizCardWebsiteController = TextEditingController();
  final _bizCardAddressController = TextEditingController();
  final _bizCardSocialController = TextEditingController();

  // Controllers for Business Information
  final _bizInfoNameController = TextEditingController();
  final _bizInfoPhoneController = TextEditingController();
  final _bizInfoEmailController = TextEditingController();
  final _bizInfoWebsiteController = TextEditingController();
  final _bizInfoAddressController = TextEditingController();
  final _bizInfoDescController = TextEditingController();
  final _bizInfoHoursController = TextEditingController();

  static const List<String> _socialPlatforms = [
    'Instagram',
    'LinkedIn',
    'YouTube',
    'Twitter / X',
    'GitHub',
    'Facebook',
    'TikTok',
    'Custom Platform',
  ];

  @override
  void initState() {
    super.initState();
    // Default preferences from settings
    _qrSize = widget.storageService.defaultQrSize;
    _selectedErrorCorrection = widget.storageService.defaultErrorCorrection;

    if (widget.editingItem != null) {
      _selectedType = widget.editingItem!.type;
      _populateFromEditingItem(widget.editingItem!);
    } else {
      _selectedType = widget.initialType;
      if (widget.initialValues != null) {
        _applyInitialValues(widget.initialValues!);
      }
    }
    _attachListeners();
  }

  void _populateFromEditingItem(QrItem item) {
    // Restore customization
    final cust = item.customization;
    _qrSize = cust.size;
    _selectedErrorCorrection = cust.errorCorrectionLevel;
    _selectedEyeShape = cust.eyeShape;
    _selectedModuleShape = cust.dataModuleShape;

    // Find color preset match if any
    for (int i = 0; i < AppColors.presets.length; i++) {
      if (AppColors.presets[i].foreground.toARGB32() == cust.foregroundColor.toARGB32() &&
          AppColors.presets[i].background.toARGB32() == cust.backgroundColor.toARGB32()) {
        _selectedColorPresetIndex = i;
        break;
      }
    }

    // Restore form values
    if (item.formData != null && item.formData!.isNotEmpty) {
      _applyInitialValues(item.formData!);
    } else {
      // Fallback: parse raw payload
      final parsed = QrPayloadBuilder.parse(item.rawPayload);
      switch (item.type) {
        case QrType.text:
          _textController.text = item.rawPayload;
          break;
        case QrType.url:
          _urlController.text = item.rawPayload;
          break;
        case QrType.wifi:
          _wifiSsidController.text = parsed.details['SSID'] ?? '';
          _wifiPasswordController.text = parsed.details['Password'] ?? '';
          _wifiSecurity = parsed.details['Security'] ?? 'WPA';
          _wifiHidden = parsed.details['Hidden'] == 'Yes';
          break;
        case QrType.contact:
          _contactFirstNameController.text = parsed.details['Name'] ?? '';
          _contactPhoneController.text = parsed.details['Phone'] ?? '';
          _contactEmailController.text = parsed.details['Email'] ?? '';
          _contactOrgController.text = parsed.details['Organization'] ?? '';
          _contactAddressController.text = parsed.details['Address'] ?? '';
          _contactWebsiteController.text = parsed.details['Website'] ?? '';
          break;
        case QrType.businessCard:
          _bizCardFullNameController.text = parsed.details['Name'] ?? '';
          _bizCardTitleController.text = parsed.details['Job Title'] ?? '';
          _bizCardCompanyController.text = parsed.details['Organization'] ?? '';
          _bizCardPhoneController.text = parsed.details['Phone'] ?? '';
          _bizCardEmailController.text = parsed.details['Email'] ?? '';
          _bizCardWebsiteController.text = parsed.details['Website'] ?? '';
          _bizCardAddressController.text = parsed.details['Address'] ?? '';
          _bizCardSocialController.text = parsed.details['Social Profile'] ?? '';
          break;
        case QrType.businessInfo:
          _bizInfoNameController.text = parsed.details['Name'] ?? '';
          _bizInfoPhoneController.text = parsed.details['Phone'] ?? '';
          _bizInfoEmailController.text = parsed.details['Email'] ?? '';
          _bizInfoWebsiteController.text = parsed.details['Website'] ?? '';
          _bizInfoAddressController.text = parsed.details['Address'] ?? '';
          _bizInfoDescController.text = parsed.details['Notes'] ?? '';
          break;
        case QrType.email:
          _emailRecipientController.text = parsed.details['To'] ?? '';
          _emailSubjectController.text = parsed.details['Subject'] ?? '';
          _emailBodyController.text = parsed.details['Message'] ?? '';
          break;
        case QrType.phone:
          _phoneController.text = parsed.details['Phone'] ?? item.rawPayload.replaceAll('tel:', '');
          break;
        case QrType.sms:
          _smsPhoneController.text = parsed.details['Phone'] ?? '';
          _smsMessageController.text = parsed.details['Message'] ?? '';
          break;
        case QrType.location:
          _locationLatController.text = parsed.details['Latitude'] ?? '';
          _locationLngController.text = parsed.details['Longitude'] ?? '';
          _locationNameController.text = parsed.details['Location'] ?? '';
          break;
        case QrType.social:
          _socialUrlController.text = parsed.details['Profile URL'] ?? item.rawPayload;
          break;
      }
    }
  }

  void _applyInitialValues(Map<String, dynamic> vals) {
    if (vals.containsKey('text')) _textController.text = vals['text'].toString();
    if (vals.containsKey('url')) _urlController.text = vals['url'].toString();
    if (vals.containsKey('ssid')) _wifiSsidController.text = vals['ssid'].toString();
    if (vals.containsKey('password')) _wifiPasswordController.text = vals['password'].toString();
    if (vals.containsKey('security')) _wifiSecurity = vals['security'].toString();
    if (vals.containsKey('hidden')) _wifiHidden = vals['hidden'] == true;
    if (vals.containsKey('firstName')) _contactFirstNameController.text = vals['firstName'].toString();
    if (vals.containsKey('lastName')) _contactLastNameController.text = vals['lastName'].toString();
    if (vals.containsKey('phone')) {
      _contactPhoneController.text = vals['phone'].toString();
      _phoneController.text = vals['phone'].toString();
      _smsPhoneController.text = vals['phone'].toString();
      _bizCardPhoneController.text = vals['phone'].toString();
      _bizInfoPhoneController.text = vals['phone'].toString();
    }
    if (vals.containsKey('email')) {
      _contactEmailController.text = vals['email'].toString();
      _emailRecipientController.text = vals['email'].toString();
      _bizCardEmailController.text = vals['email'].toString();
      _bizInfoEmailController.text = vals['email'].toString();
    }
    if (vals.containsKey('company')) {
      _contactOrgController.text = vals['company'].toString();
      _bizCardCompanyController.text = vals['company'].toString();
    }
    if (vals.containsKey('address')) {
      _contactAddressController.text = vals['address'].toString();
      _bizCardAddressController.text = vals['address'].toString();
      _bizInfoAddressController.text = vals['address'].toString();
    }
    if (vals.containsKey('website')) {
      _contactWebsiteController.text = vals['website'].toString();
      _bizCardWebsiteController.text = vals['website'].toString();
      _bizInfoWebsiteController.text = vals['website'].toString();
    }
    if (vals.containsKey('subject')) _emailSubjectController.text = vals['subject'].toString();
    if (vals.containsKey('body')) _emailBodyController.text = vals['body'].toString();
    if (vals.containsKey('message')) _smsMessageController.text = vals['message'].toString();
    if (vals.containsKey('name')) _locationNameController.text = vals['name'].toString();
    if (vals.containsKey('latitude')) _locationLatController.text = vals['latitude'].toString();
    if (vals.containsKey('longitude')) _locationLngController.text = vals['longitude'].toString();
    if (vals.containsKey('platform')) _socialPlatform = vals['platform'].toString();
    if (vals.containsKey('socialUrl')) {
      _socialUrlController.text = vals['socialUrl'].toString();
      _bizCardSocialController.text = vals['socialUrl'].toString();
    }
    if (vals.containsKey('fullName')) _bizCardFullNameController.text = vals['fullName'].toString();
    if (vals.containsKey('jobTitle')) _bizCardTitleController.text = vals['jobTitle'].toString();
    if (vals.containsKey('businessName')) _bizInfoNameController.text = vals['businessName'].toString();
    if (vals.containsKey('description')) _bizInfoDescController.text = vals['description'].toString();
    if (vals.containsKey('businessHours')) _bizInfoHoursController.text = vals['businessHours'].toString();
  }

  void _applyPreset(QrPreset preset) {
    setState(() {
      _selectedType = preset.type;
      final cust = preset.customization;
      _qrSize = cust.size;
      _selectedErrorCorrection = cust.errorCorrectionLevel;
      _selectedEyeShape = cust.eyeShape;
      _selectedModuleShape = cust.dataModuleShape;

      for (int i = 0; i < AppColors.presets.length; i++) {
        if (AppColors.presets[i].foreground.toARGB32() == cust.foregroundColor.toARGB32() &&
            AppColors.presets[i].background.toARGB32() == cust.backgroundColor.toARGB32()) {
          _selectedColorPresetIndex = i;
          break;
        }
      }

      if (preset.fields.isNotEmpty) {
        _applyInitialValues(preset.fields);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied preset "${preset.name}"'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveCurrentAsPreset() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save as Preset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Save your current QR style, shape, and configurations for quick reuse.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Preset Name *',
                hintText: 'e.g. Dark Cyan Card',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                final newPreset = QrPreset(
                  id: const Uuid().v4(),
                  name: name,
                  type: _selectedType,
                  defaultTitle: _buildTitle(),
                  customization: _currentCustomization,
                  fields: _currentFormData,
                  createdAt: DateTime.now(),
                );
                await widget.storageService.savePreset(newPreset);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Saved preset "$name"'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Save Preset'),
          ),
        ],
      ),
    );
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
    _locationNameController.dispose();
    _locationLatController.dispose();
    _locationLngController.dispose();
    _socialUrlController.dispose();
    _bizCardFullNameController.dispose();
    _bizCardTitleController.dispose();
    _bizCardCompanyController.dispose();
    _bizCardPhoneController.dispose();
    _bizCardEmailController.dispose();
    _bizCardWebsiteController.dispose();
    _bizCardAddressController.dispose();
    _bizCardSocialController.dispose();
    _bizInfoNameController.dispose();
    _bizInfoPhoneController.dispose();
    _bizInfoEmailController.dispose();
    _bizInfoWebsiteController.dispose();
    _bizInfoAddressController.dispose();
    _bizInfoDescController.dispose();
    _bizInfoHoursController.dispose();
    super.dispose();
  }

  void _attachListeners() {
    final controllers = [
      _textController,
      _urlController,
      _wifiSsidController,
      _wifiPasswordController,
      _contactFirstNameController,
      _contactLastNameController,
      _contactPhoneController,
      _contactEmailController,
      _phoneController,
      _smsPhoneController,
      _smsMessageController,
      _locationLatController,
      _locationLngController,
      _locationNameController,
      _socialUrlController,
      _bizCardFullNameController,
      _bizCardTitleController,
      _bizCardCompanyController,
      _bizInfoNameController,
      _bizInfoPhoneController,
      _emailRecipientController,
      _emailSubjectController,
    ];
    for (final c in controllers) {
      c.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  QrCustomization get _currentCustomization {
    final preset = AppColors.presets[_selectedColorPresetIndex];
    return QrCustomization(
      foregroundColor: preset.foreground,
      backgroundColor: preset.background,
      size: _qrSize,
      errorCorrectionLevel: _selectedErrorCorrection,
      eyeShape: _selectedEyeShape,
      dataModuleShape: _selectedModuleShape,
    );
  }

  void _resetCustomization() {
    setState(() {
      _selectedColorPresetIndex = 0;
      _selectedErrorCorrection = widget.storageService.defaultErrorCorrection;
      _qrSize = widget.storageService.defaultQrSize;
      _selectedEyeShape = 'square';
      _selectedModuleShape = 'square';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Customization reset to defaults'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Map<String, dynamic> get _currentFormData {
    switch (_selectedType) {
      case QrType.text:
        return {'text': _textController.text.trim()};
      case QrType.url:
        return {'url': _urlController.text.trim()};
      case QrType.wifi:
        return {
          'ssid': _wifiSsidController.text.trim(),
          'password': _wifiPasswordController.text.trim(),
          'security': _wifiSecurity,
          'hidden': _wifiHidden,
        };
      case QrType.contact:
        return {
          'firstName': _contactFirstNameController.text.trim(),
          'lastName': _contactLastNameController.text.trim(),
          'phone': _contactPhoneController.text.trim(),
          'email': _contactEmailController.text.trim(),
          'company': _contactOrgController.text.trim(),
          'address': _contactAddressController.text.trim(),
          'website': _contactWebsiteController.text.trim(),
        };
      case QrType.businessCard:
        return {
          'fullName': _bizCardFullNameController.text.trim(),
          'jobTitle': _bizCardTitleController.text.trim(),
          'company': _bizCardCompanyController.text.trim(),
          'phone': _bizCardPhoneController.text.trim(),
          'email': _bizCardEmailController.text.trim(),
          'website': _bizCardWebsiteController.text.trim(),
          'address': _bizCardAddressController.text.trim(),
          'socialUrl': _bizCardSocialController.text.trim(),
        };
      case QrType.businessInfo:
        return {
          'businessName': _bizInfoNameController.text.trim(),
          'phone': _bizInfoPhoneController.text.trim(),
          'email': _bizInfoEmailController.text.trim(),
          'website': _bizInfoWebsiteController.text.trim(),
          'address': _bizInfoAddressController.text.trim(),
          'description': _bizInfoDescController.text.trim(),
          'businessHours': _bizInfoHoursController.text.trim(),
        };
      case QrType.email:
        return {
          'email': _emailRecipientController.text.trim(),
          'subject': _emailSubjectController.text.trim(),
          'body': _emailBodyController.text.trim(),
        };
      case QrType.phone:
        return {'phone': _phoneController.text.trim()};
      case QrType.sms:
        return {
          'phone': _smsPhoneController.text.trim(),
          'message': _smsMessageController.text.trim(),
        };
      case QrType.location:
        return {
          'name': _locationNameController.text.trim(),
          'latitude': _locationLatController.text.trim(),
          'longitude': _locationLngController.text.trim(),
        };
      case QrType.social:
        return {
          'platform': _socialPlatform,
          'socialUrl': _socialUrlController.text.trim(),
        };
    }
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
      case QrType.businessCard:
        return QrPayloadBuilder.buildBusinessCard(
          fullName: _bizCardFullNameController.text,
          jobTitle: _bizCardTitleController.text,
          company: _bizCardCompanyController.text,
          phone: _bizCardPhoneController.text,
          email: _bizCardEmailController.text,
          website: _bizCardWebsiteController.text,
          address: _bizCardAddressController.text,
          socialUrl: _bizCardSocialController.text,
        );
      case QrType.businessInfo:
        return QrPayloadBuilder.buildBusinessInfo(
          businessName: _bizInfoNameController.text,
          phone: _bizInfoPhoneController.text,
          email: _bizInfoEmailController.text,
          website: _bizInfoWebsiteController.text,
          address: _bizInfoAddressController.text,
          description: _bizInfoDescController.text,
          businessHours: _bizInfoHoursController.text,
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
      case QrType.location:
        final lat = double.tryParse(_locationLatController.text.trim()) ?? 0.0;
        final lng = double.tryParse(_locationLngController.text.trim()) ?? 0.0;
        return QrPayloadBuilder.buildLocation(
          latitude: lat,
          longitude: lng,
          name: _locationNameController.text.trim(),
        );
      case QrType.social:
        return QrPayloadBuilder.buildSocial(
          platform: _socialPlatform,
          usernameOrUrl: _socialUrlController.text.trim(),
        );
    }
  }

  String _buildTitle() {
    switch (_selectedType) {
      case QrType.text:
        final t = _textController.text.trim();
        return t.length > 25 ? '${t.substring(0, 25)}...' : (t.isNotEmpty ? t : 'Text QR');
      case QrType.url:
        final u = _urlController.text.trim();
        return u.isNotEmpty ? u : 'Website URL';
      case QrType.wifi:
        return 'Wi-Fi: ${_wifiSsidController.text.trim()}';
      case QrType.contact:
        final name =
            '${_contactFirstNameController.text.trim()} ${_contactLastNameController.text.trim()}'
                .trim();
        return name.isNotEmpty ? name : 'New Contact';
      case QrType.businessCard:
        final name = _bizCardFullNameController.text.trim();
        return name.isNotEmpty ? '$name (Biz Card)' : 'Business Card';
      case QrType.businessInfo:
        final bName = _bizInfoNameController.text.trim();
        return bName.isNotEmpty ? bName : 'Business Information';
      case QrType.email:
        return 'Email: ${_emailRecipientController.text.trim()}';
      case QrType.phone:
        return 'Call ${_phoneController.text.trim()}';
      case QrType.sms:
        return 'SMS to ${_smsPhoneController.text.trim()}';
      case QrType.location:
        final name = _locationNameController.text.trim();
        if (name.isNotEmpty) return name;
        return 'Location: ${_locationLatController.text.trim()}, ${_locationLngController.text.trim()}';
      case QrType.social:
        return '$_socialPlatform Profile';
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
      case QrType.businessCard:
        final title = _bizCardTitleController.text.trim();
        final company = _bizCardCompanyController.text.trim();
        if (title.isNotEmpty && company.isNotEmpty) return '$title at $company';
        if (title.isNotEmpty) return title;
        return _bizCardPhoneController.text.trim();
      case QrType.businessInfo:
        final phone = _bizInfoPhoneController.text.trim();
        final hours = _bizInfoHoursController.text.trim();
        if (hours.isNotEmpty) return 'Hours: $hours';
        return phone.isNotEmpty ? phone : 'Business details';
      case QrType.email:
        return _emailSubjectController.text.trim().isNotEmpty
            ? _emailSubjectController.text.trim()
            : 'Email compose';
      case QrType.phone:
        return 'Telephone Number';
      case QrType.sms:
        return _smsMessageController.text.trim();
      case QrType.location:
        return 'Lat: ${_locationLatController.text.trim()}, Lng: ${_locationLngController.text.trim()}';
      case QrType.social:
        return _socialUrlController.text.trim();
    }
  }

  void _generateQrCode({bool saveAsNew = false}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_currentCustomization.hasSufficientContrast) {
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Low Contrast Warning'),
            ],
          ),
          content: Text(
            'The selected colors have a low contrast ratio (${_currentCustomization.contrastRatio.toStringAsFixed(1)}:1). Camera scanners might fail to decode this code.\n\nDo you want to auto-fix the contrast or generate anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx, false);
                setState(() => _selectedColorPresetIndex = 0);
              },
              child: const Text('Auto-Fix Contrast'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Generate Anyway'),
            ),
          ],
        ),
      );
      if (shouldProceed != true) return;
    }

    final payload = _buildPayload();
    final title = _buildTitle();
    final subtitle = _buildSubtitle();
    final formData = _currentFormData;

    final String itemId = (widget.editingItem != null && !saveAsNew)
        ? widget.editingItem!.id
        : const Uuid().v4();

    final DateTime createdAt = (widget.editingItem != null && !saveAsNew)
        ? widget.editingItem!.createdAt
        : DateTime.now();

    final bool isFavorite = (widget.editingItem != null && !saveAsNew)
        ? widget.editingItem!.isFavorite
        : false;

    final updatedOrNewItem = QrItem(
      id: itemId,
      type: _selectedType,
      title: title,
      subtitle: subtitle,
      rawPayload: payload,
      createdAt: createdAt,
      customization: _currentCustomization,
      isFavorite: isFavorite,
      formData: formData,
    );

    // Save to persistent storage
    await widget.storageService.saveItem(updatedOrNewItem);

    if (!mounted) return;

    final isEditUpdate = widget.editingItem != null && !saveAsNew;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEditUpdate
            ? 'Updated "$title" successfully!'
            : 'Generated and saved "$title"!'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Navigate to preview screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QrPreviewScreen(
          item: updatedOrNewItem,
          storageService: widget.storageService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.editingItem != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit QR Code' : 'Create QR Code'),
        actions: [
          // Presets Action
          IconButton(
            icon: const Icon(Icons.bookmark_outline_rounded),
            tooltip: 'Presets',
            onPressed: () async {
              final selected = await Navigator.push<QrPreset>(
                context,
                MaterialPageRoute(
                  builder: (context) => PresetsScreen(
                    storageService: widget.storageService,
                    onUsePreset: (preset) {
                      Navigator.pop(context, preset);
                    },
                  ),
                ),
              );
              if (selected != null) {
                _applyPreset(selected);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            children: [
              // Editing Banner if active
              if (isEditing) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Editing: "${widget.editingItem!.title}"\nYou can update the existing record or save as a new copy.',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 1. QR Type Selection Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select QR Type',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                  ),
                  Text(
                    '${QrType.values.length} Formats',
                    style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                  ),
                ],
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
                              style: TextStyle(
                                fontSize: 11,
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
              const SizedBox(height: 14),

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

              // 2. Dynamic Input Form for selected type
              _buildTypeForm(),
              const SizedBox(height: 24),

              // 3. Live Preview Card before generation
              _buildLivePreviewCard(isDark),
              const SizedBox(height: 20),

              // 4. Advanced QR Customization Accordion
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
                    'Advanced Customization & Presets',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Colors, shapes, size, and save presets',
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
                          const SizedBox(height: 8),

                          // Presets quick actions bar inside customization
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                onPressed: _saveCurrentAsPreset,
                                icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                                label: const Text('Save as Preset', style: TextStyle(fontSize: 12)),
                              ),
                              TextButton(
                                onPressed: _resetCustomization,
                                child: const Text('Reset', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Contrast warning if insufficient
                          _buildContrastWarning(isDark),

                          // Built-in Visual Presets (Classic, Dark, Soft, Business, Minimal)
                          _buildVisualPresetsSelector(isDark),
                          const SizedBox(height: 16),

                          // Color Palette Presets
                          const Text(
                            'Color Palette',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? AppColors.primary
                                                : (isDark
                                                    ? AppColors.darkTextSecondary
                                                    : AppColors
                                                        .lightTextSecondary),
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

                          // Module Pattern & Eye Corner Styles
                          Row(
                            children: [
                              // Module Pattern Style
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Module Pattern',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        _shapeChoiceChip(
                                          label: 'Square',
                                          icon: Icons.square_rounded,
                                          isSelected:
                                              _selectedModuleShape == 'square',
                                          onTap: () => setState(() =>
                                              _selectedModuleShape = 'square'),
                                        ),
                                        const SizedBox(width: 8),
                                        _shapeChoiceChip(
                                          label: 'Circles',
                                          icon: Icons.circle_rounded,
                                          isSelected:
                                              _selectedModuleShape == 'circle',
                                          onTap: () => setState(() =>
                                              _selectedModuleShape = 'circle'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Eye Corner Style
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Corner Style',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        _shapeChoiceChip(
                                          label: 'Square',
                                          icon: Icons.crop_square_rounded,
                                          isSelected:
                                              _selectedEyeShape == 'square',
                                          onTap: () => setState(() =>
                                              _selectedEyeShape = 'square'),
                                        ),
                                        const SizedBox(width: 8),
                                        _shapeChoiceChip(
                                          label: 'Circle',
                                          icon: Icons.circle_outlined,
                                          isSelected:
                                              _selectedEyeShape == 'circle',
                                          onTap: () => setState(
                                              () => _selectedEyeShape = 'circle'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // QR Size Slider
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'QR Code Size',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${_qrSize.toInt()} px',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          Slider(
                            value: _qrSize,
                            min: 160.0,
                            max: 320.0,
                            divisions: 8,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setState(() => _qrSize = val);
                            },
                          ),
                          const SizedBox(height: 8),

                          // Error Correction Level
                          const Text(
                            'Error Correction Resilience',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Higher resilience preserves scannability even on damaged or curved surfaces.',
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

              // 5. Action Buttons (Update Existing vs Save as New vs Generate)
              if (isEditing) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _generateQrCode(saveAsNew: false),
                        icon: const Icon(Icons.check_circle_rounded, size: 20),
                        label: const Text('Update Existing'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _generateQrCode(saveAsNew: true),
                        icon: const Icon(Icons.copy_all_rounded, size: 20),
                        label: const Text('Save as New'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _generateQrCode(),
                  icon: const Icon(Icons.qr_code_rounded, size: 22),
                  label: const Text('Generate & Preview QR'),
                ),
              ],
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLivePreviewCard(bool isDark) {
    final previewPayload = _buildPayload();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.visibility_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  const Text(
                    'Live QR Preview',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Text(
                _selectedType.shortName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _selectedType.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: QrRenderView(
              data: previewPayload.isNotEmpty ? previewPayload : 'https://preview.qr',
              customization: _currentCustomization,
              size: 150,
              showContainer: false,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            previewPayload.isNotEmpty
                ? 'Ready to generate'
                : 'Enter details above to populate payload',
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          _buildEnteredInfoSummary(isDark),
        ],
      ),
    );
  }

  Widget _buildContrastWarning(bool isDark) {
    final ratio = _currentCustomization.contrastRatio;
    if (ratio >= 3.0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Low Contrast Warning (${ratio.toStringAsFixed(1)}:1)',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Camera sensors may struggle to scan this QR code. A contrast ratio of 3.0:1 or higher is recommended.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () {
              setState(() {
                _selectedColorPresetIndex = 0; // Classic Black on White (21:1)
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Auto-fixed contrast to Classic Black (21:1 ratio)'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Auto Fix', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualPresetsSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Visual Design Presets',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            Text(
              'One-tap styles',
              style: TextStyle(fontSize: 11.5, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: QrDesignPreset.builtInPresets.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final preset = QrDesignPreset.builtInPresets[index];
              final isMatching = _selectedEyeShape == preset.customization.eyeShape &&
                  _selectedModuleShape == preset.customization.dataModuleShape &&
                  AppColors.presets[_selectedColorPresetIndex].foreground.toARGB32() ==
                      preset.customization.foregroundColor.toARGB32() &&
                  AppColors.presets[_selectedColorPresetIndex].background.toARGB32() ==
                      preset.customization.backgroundColor.toARGB32();

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    _selectedEyeShape = preset.customization.eyeShape;
                    _selectedModuleShape = preset.customization.dataModuleShape;
                    _selectedErrorCorrection = preset.customization.errorCorrectionLevel;

                    for (int i = 0; i < AppColors.presets.length; i++) {
                      if (AppColors.presets[i].foreground.toARGB32() ==
                              preset.customization.foregroundColor.toARGB32() &&
                          AppColors.presets[i].background.toARGB32() ==
                              preset.customization.backgroundColor.toARGB32()) {
                        _selectedColorPresetIndex = i;
                        break;
                      }
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Applied "${preset.name}" preset: ${preset.description}'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  width: 90,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: isMatching
                        ? AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12)
                        : (isDark ? AppColors.darkSurface : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isMatching ? AppColors.primary : Colors.grey.shade300,
                      width: isMatching ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        preset.icon,
                        size: 20,
                        color: isMatching ? AppColors.primary : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        preset.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isMatching ? FontWeight.w700 : FontWeight.w500,
                          color: isMatching ? AppColors.primary : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnteredInfoSummary(bool isDark) {
    Widget summaryContent;

    switch (_selectedType) {
      case QrType.url:
        final raw = _urlController.text.trim();
        final hasUrl = raw.isNotEmpty && raw != 'https://' && raw != 'http://';
        summaryContent = Row(
          children: [
            const Icon(Icons.link_rounded, size: 16, color: AppColors.typeUrl),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasUrl ? QrPayloadBuilder.buildUrl(raw) : 'Enter URL above to view target',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: hasUrl ? FontWeight.w600 : FontWeight.normal,
                  color: hasUrl ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
                ),
              ),
            ),
          ],
        );
        break;

      case QrType.wifi:
        final ssid = _wifiSsidController.text.trim();
        final hasPass = _wifiPasswordController.text.trim().isNotEmpty;
        final sec = _wifiSecurity;
        final isNoPass = sec == 'nopass';
        summaryContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wifi_rounded, size: 16, color: AppColors.typeWifi),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ssid.isNotEmpty ? 'Network: $ssid' : 'Enter Wi-Fi network SSID',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: ssid.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                      color: ssid.isNotEmpty ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              'Security: $sec • ${isNoPass ? "Open Network" : (hasPass ? "Password configured (●●●●)" : "No password entered")}',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        );
        break;

      case QrType.contact:
        final fName = _contactFirstNameController.text.trim();
        final lName = _contactLastNameController.text.trim();
        final fullName = '$fName $lName'.trim();
        final phone = _contactPhoneController.text.trim();
        summaryContent = Row(
          children: [
            const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.typeContact),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                fullName.isNotEmpty
                    ? '$fullName${phone.isNotEmpty ? " • $phone" : ""}'
                    : 'Enter contact name and details',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: fullName.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                  color: fullName.isNotEmpty ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
                ),
              ),
            ),
          ],
        );
        break;

      case QrType.businessCard:
        final name = _bizCardFullNameController.text.trim();
        final title = _bizCardTitleController.text.trim();
        final company = _bizCardCompanyController.text.trim();
        summaryContent = Row(
          children: [
            const Icon(Icons.badge_outlined, size: 16, color: AppColors.typeBusinessCard),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name.isNotEmpty
                    ? '$name${title.isNotEmpty ? " • $title" : ""}${company.isNotEmpty ? " ($company)" : ""}'
                    : 'Enter full business card profile',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: name.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                  color: name.isNotEmpty ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
                ),
              ),
            ),
          ],
        );
        break;

      case QrType.businessInfo:
        final bName = _bizInfoNameController.text.trim();
        final phone = _bizInfoPhoneController.text.trim();
        summaryContent = Row(
          children: [
            const Icon(Icons.storefront_rounded, size: 16, color: AppColors.typeBusinessInfo),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                bName.isNotEmpty
                    ? '$bName${phone.isNotEmpty ? " • $phone" : ""}'
                    : 'Enter business name & hours',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: bName.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                  color: bName.isNotEmpty ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
                ),
              ),
            ),
          ],
        );
        break;

      case QrType.email:
        final email = _emailRecipientController.text.trim();
        final sub = _emailSubjectController.text.trim();
        summaryContent = Row(
          children: [
            const Icon(Icons.mail_outline_rounded, size: 16, color: AppColors.typeEmail),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                email.isNotEmpty
                    ? 'To: $email${sub.isNotEmpty ? " • Subject: $sub" : ""}'
                : 'Enter recipient email & subject',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: email.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                  color: email.isNotEmpty ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
                ),
              ),
            ),
          ],
        );
        break;

      case QrType.phone:
        final phone = _phoneController.text.trim();
        summaryContent = Row(
          children: [
            const Icon(Icons.phone_in_talk_rounded, size: 16, color: AppColors.typePhone),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                phone.isNotEmpty ? 'Dial: $phone' : 'Enter target telephone number',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: phone.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                  color: phone.isNotEmpty ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
                ),
              ),
            ),
          ],
        );
        break;

      case QrType.sms:
        final phone = _smsPhoneController.text.trim();
        final msg = _smsMessageController.text.trim();
        summaryContent = Row(
          children: [
            const Icon(Icons.sms_outlined, size: 16, color: AppColors.typeSms),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                phone.isNotEmpty
                    ? 'SMS to $phone${msg.isNotEmpty ? ": \"$msg\"" : ""}'
                    : 'Enter recipient phone and message template',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: phone.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                  color: phone.isNotEmpty ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
                ),
              ),
            ),
          ],
        );
        break;

      case QrType.location:
        final name = _locationNameController.text.trim();
        final lat = _locationLatController.text.trim();
        final lng = _locationLngController.text.trim();
        summaryContent = Row(
          children: [
            const Icon(Icons.location_on_rounded, size: 16, color: AppColors.typeLocation),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                lat.isNotEmpty && lng.isNotEmpty
                    ? '${name.isNotEmpty ? "$name • " : ""}Coordinates: $lat, $lng'
                    : 'Enter map latitude and longitude coordinates',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: lat.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                  color: lat.isNotEmpty ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
                ),
              ),
            ),
          ],
        );
        break;

      case QrType.social:
        final handle = _socialUrlController.text.trim();
        summaryContent = Row(
          children: [
            const Icon(Icons.share_rounded, size: 16, color: AppColors.typeSocial),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                handle.isNotEmpty
                    ? '$_socialPlatform: ${QrPayloadBuilder.buildSocial(platform: _socialPlatform, usernameOrUrl: handle)}'
                    : 'Select platform and enter handle or URL',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: handle.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                  color: handle.isNotEmpty ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
                ),
              ),
            ),
          ],
        );
        break;

      case QrType.text:
        final text = _textController.text.trim();
        summaryContent = Row(
          children: [
            const Icon(Icons.notes_rounded, size: 16, color: AppColors.typeText),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text.isNotEmpty
                    ? '${text.length > 50 ? "${text.substring(0, 50)}..." : text} (${text.length} chars)'
                    : 'Enter plain text or note content',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: text.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                  color: text.isNotEmpty ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
                ),
              ),
            ),
          ],
        );
        break;
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: summaryContent,
    );
  }

  Widget _shapeChoiceChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : null,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : null,
                ),
              ),
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
      case QrType.businessCard:
        return _buildBusinessCardForm();
      case QrType.businessInfo:
        return _buildBusinessInfoForm();
      case QrType.email:
        return _buildEmailForm();
      case QrType.phone:
        return _buildPhoneForm();
      case QrType.sms:
        return _buildSmsForm();
      case QrType.location:
        return _buildLocationForm();
      case QrType.social:
        return _buildSocialForm();
    }
  }

  // 1. Text Form
  Widget _buildTextForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _textController,
          label: 'Plain Text or Note',
          hint: 'Enter any text message, serial number, or note...',
          prefixIcon: Icons.notes_rounded,
          maxLines: 4,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Please enter text content';
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _urlController,
          label: 'Website URL',
          hint: 'https://example.com',
          prefixIcon: Icons.link_rounded,
          keyboardType: TextInputType.url,
          validator: (val) {
            if (val == null || val.trim().isEmpty || val.trim() == 'https://') {
              return 'Please enter a valid website URL';
            }
            return null;
          },
        ),
      ],
    );
  }

  // 3. Wi-Fi Form
  Widget _buildWifiForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _wifiSsidController,
          label: 'Network Name (SSID) *',
          hint: 'MyHomeWiFi',
          prefixIcon: Icons.wifi_rounded,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Network SSID name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: _wifiPasswordController,
          label: 'Wi-Fi Password',
          hint: 'Enter wireless password',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _wifiObscurePass,
          validator: (val) {
            if (_wifiSecurity != 'nopass' && (val == null || val.trim().isEmpty)) {
              return 'Password is required for secured network';
            }
            if (_wifiSecurity == 'WPA' && val != null && val.trim().isNotEmpty && val.trim().length < 8) {
              return 'WPA password must be at least 8 characters';
            }
            return null;
          },
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
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _wifiSecurity,
          decoration: const InputDecoration(
            labelText: 'Security Protocol',
            prefixIcon: Icon(Icons.security_rounded),
          ),
          items: const [
            DropdownMenuItem(value: 'WPA', child: Text('WPA / WPA2 / WPA3')),
            DropdownMenuItem(value: 'WEP', child: Text('WEP')),
            DropdownMenuItem(value: 'nopass', child: Text('Open (No Password)')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _wifiSecurity = val);
          },
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Hidden Network', style: TextStyle(fontSize: 14)),
          subtitle: const Text(
            'Enable if network SSID is not broadcasted',
            style: TextStyle(fontSize: 12),
          ),
          value: _wifiHidden,
          onChanged: (val) => setState(() => _wifiHidden = val),
        ),
      ],
    );
  }

  // 4. Contact Form (vCard)
  Widget _buildContactForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _contactFirstNameController,
                label: 'First Name *',
                hint: 'John',
                prefixIcon: Icons.person_outline_rounded,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'First name is required';
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
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: _contactEmailController,
          label: 'Email Address',
          hint: 'john.doe@example.com',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: _contactOrgController,
          label: 'Organization / Company',
          hint: 'Acme Corp',
          prefixIcon: Icons.business_rounded,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: _contactAddressController,
          label: 'Physical Address',
          hint: '123 Market St, Suite 400',
          prefixIcon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: _contactWebsiteController,
          label: 'Website',
          hint: 'https://johndoe.com',
          prefixIcon: Icons.language_rounded,
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  // 5. Business Card Form (Requirement: Business Card QR)
  Widget _buildBusinessCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _bizCardFullNameController,
          label: 'Full Name *',
          hint: 'Sarah Connor',
          prefixIcon: Icons.badge_outlined,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Full name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _bizCardTitleController,
                label: 'Job Title',
                hint: 'Chief Technology Officer',
                prefixIcon: Icons.work_outline_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: _bizCardCompanyController,
                label: 'Company',
                hint: 'Cyberdyne Systems',
                prefixIcon: Icons.business_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _bizCardPhoneController,
                label: 'Phone',
                hint: '+1 555 0199',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: _bizCardEmailController,
                label: 'Work Email',
                hint: 'sarah@cyberdyne.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: _bizCardWebsiteController,
          label: 'Website / Portfolio',
          hint: 'https://cyberdyne.com/sarah',
          prefixIcon: Icons.language_rounded,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: _bizCardAddressController,
          label: 'Office Address',
          hint: '400 Enterprise Blvd, Austin, TX',
          prefixIcon: Icons.place_outlined,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: _bizCardSocialController,
          label: 'Social / LinkedIn URL',
          hint: 'https://linkedin.com/in/sarah-connor',
          prefixIcon: Icons.link_rounded,
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  // 6. Business Information Form (Requirement: Business Info QR)
  Widget _buildBusinessInfoForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _bizInfoNameController,
          label: 'Business Name *',
          hint: 'Green Leaf Cafe & Roastery',
          prefixIcon: Icons.storefront_rounded,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Business name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _bizInfoPhoneController,
                label: 'Business Phone',
                hint: '+1 555 4321',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: _bizInfoEmailController,
                label: 'Contact Email',
                hint: 'info@greenleaf.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: _bizInfoWebsiteController,
          label: 'Business Website',
          hint: 'https://greenleafcafe.com',
          prefixIcon: Icons.language_rounded,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: _bizInfoAddressController,
          label: 'Store / Location Address',
          hint: '742 Evergreen Terrace, Springfield',
          prefixIcon: Icons.place_outlined,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: _bizInfoHoursController,
          label: 'Business Hours Text',
          hint: 'Mon - Fri: 8:00 AM - 6:00 PM • Sat: 9:00 AM - 3:00 PM',
          prefixIcon: Icons.access_time_rounded,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: _bizInfoDescController,
          label: 'Business Description',
          hint: 'Specialty organic coffee, artisan pastries & free high-speed Wi-Fi.',
          prefixIcon: Icons.description_outlined,
          maxLines: 3,
        ),
      ],
    );
  }

  // 7. Email Form
  Widget _buildEmailForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _emailRecipientController,
          label: 'Recipient Email Address *',
          hint: 'support@company.com',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Please enter recipient email';
            }
            final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
            if (!emailRegex.hasMatch(val.trim())) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: _emailSubjectController,
          label: 'Subject Line',
          hint: 'e.g. Inquiring about services',
          prefixIcon: Icons.subject_rounded,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: _emailBodyController,
          label: 'Email Body / Message',
          hint: 'Pre-filled message for the recipient...',
          prefixIcon: Icons.message_outlined,
          maxLines: 3,
        ),
      ],
    );
  }

  // 8. Phone Form
  Widget _buildPhoneForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _phoneController,
          label: 'Phone Number *',
          hint: '+1 234 567 8900',
          prefixIcon: Icons.phone_in_talk_rounded,
          keyboardType: TextInputType.phone,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Phone number cannot be empty';
            }
            final clean = val.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
            if (clean.length < 3) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
        ),
      ],
    );
  }

  // 9. SMS Form
  Widget _buildSmsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _smsPhoneController,
          label: 'Recipient Phone Number *',
          hint: '+1 234 567 8900',
          prefixIcon: Icons.sms_outlined,
          keyboardType: TextInputType.phone,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Recipient phone is required';
            }
            final clean = val.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
            if (clean.length < 3) {
              return 'Please enter a valid recipient number';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: _smsMessageController,
          label: 'Pre-filled SMS Message',
          hint: 'Type template message...',
          prefixIcon: Icons.message_outlined,
          maxLines: 3,
        ),
      ],
    );
  }

  // 10. Location Form
  Widget _buildLocationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _locationNameController,
          label: 'Location Name / Place (Optional)',
          hint: 'Times Square, New York',
          prefixIcon: Icons.place_outlined,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _locationLatController,
                label: 'Latitude *',
                hint: '40.7580',
                prefixIcon: Icons.explore_outlined,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true, signed: true),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Latitude is required';
                  }
                  final lat = double.tryParse(val.trim());
                  if (lat == null || lat < -90.0 || lat > 90.0) {
                    return 'Must be between -90 and 90';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: _locationLngController,
                label: 'Longitude *',
                hint: '-73.9855',
                prefixIcon: Icons.explore_outlined,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true, signed: true),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Longitude is required';
                  }
                  final lng = double.tryParse(val.trim());
                  if (lng == null || lng < -180.0 || lng > 180.0) {
                    return 'Must be between -180 and 180';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 11. Social Profile Form
  Widget _buildSocialForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _socialPlatform,
          decoration: const InputDecoration(
            labelText: 'Social Media Platform',
            prefixIcon: Icon(Icons.share_rounded),
          ),
          items: _socialPlatforms.map((p) {
            return DropdownMenuItem(value: p, child: Text(p));
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _socialPlatform = val);
          },
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: _socialUrlController,
          label: 'Username or Profile URL *',
          hint: 'username or https://...',
          prefixIcon: Icons.person_pin_rounded,
          keyboardType: TextInputType.url,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Please enter username or profile URL';
            }
            return null;
          },
        ),
      ],
    );
  }
}
