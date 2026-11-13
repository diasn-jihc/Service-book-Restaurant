import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/user.dart';

class VerifyPhoneScreen extends StatefulWidget {
  const VerifyPhoneScreen({
    super.key,
    required this.phone,
    required this.onVerify,
    required this.onResend,
  });

  final String phone;
  final Future<AppUser?> Function(String code) onVerify;
  final Future<void> Function() onResend;

  @override
  State<VerifyPhoneScreen> createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends State<VerifyPhoneScreen> {
  final _codeController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_codeController.text.trim().length != 6) {
      setState(() => _error = 'Введите шестизначный код из SMS.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await widget.onVerify(_codeController.text.trim());
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _busy = false;
          _error = 'Не удалось подтвердить номер. Проверьте код и повторите.';
        });
        return;
      }
      Navigator.of(context).pop(user);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Не удалось подтвердить номер. Повторите попытку.';
      });
    }
  }

  Future<void> _resend() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onResend();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Код отправлен повторно.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Не удалось отправить код повторно.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Подтверждение телефона')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Введите код из SMS, отправленного на ${widget.phone}.'),
          const SizedBox(height: 20),
          TextField(
            controller: _codeController,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(
              labelText: 'Код подтверждения',
              prefixIcon: Icon(Icons.sms_outlined),
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _error!.startsWith('Код отправлен')
                    ? Colors.greenAccent
                    : Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _verify,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Text('Подтвердить номер'),
          ),
          TextButton(
            onPressed: _busy ? null : _resend,
            child: const Text('Отправить код ещё раз'),
          ),
        ],
      ),
    );
  }
}
