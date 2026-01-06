import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _Section(
                title: 'Effective Date',
                body: 'Updated on Jan 6, 2026.',
              ),
              _Section(
                title: 'Information We Collect',
                body:
                    'Account data (name, email, profile details), usage data, messages, attachments you send, and payment metadata handled by payment processors.',
              ),
              _Section(
                title: 'How We Use Information',
                body:
                    'To provide authentication, subscriptions, messaging, notifications, scheduling, support, fraud prevention, and to improve the service.',
              ),
              _Section(
                title: 'Sharing',
                body:
                    'We share data with service providers for hosting, analytics, messaging, and payments; between matched users for mentoring; and when required for safety or legal compliance.',
              ),
              _Section(
                title: 'Retention',
                body:
                    'We retain data while your account is active and as needed for service, legal, and security needs, then delete or de-identify when no longer required.',
              ),
              _Section(
                title: 'Your Choices',
                body:
                    'You can update profile info, request deletion, and manage notifications in settings. Some data may be kept for legal or security reasons.',
              ),
              _Section(
                title: 'Security',
                body:
                    'We use technical and organizational safeguards but cannot guarantee absolute security. Protect your credentials and report suspected misuse.',
              ),
              _Section(
                title: 'Children',
                body:
                    'The service is not directed to children under the minimum legal age. Guardian consent is required where applicable.',
              ),
              _Section(
                title: 'International Transfers',
                body:
                    'Data may be processed in other countries with protections consistent with this policy and applicable law.',
              ),
              _Section(
                title: 'Contact',
                body:
                    'Email support at skillup@gmail.com. Replace this with your actual support contact before publishing.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(fontSize: 14, height: 1.35),
          ),
        ],
      ),
    );
  }
}
