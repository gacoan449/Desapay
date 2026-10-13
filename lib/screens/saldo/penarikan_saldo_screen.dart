import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../services/withdrawal_service.dart';

class PenarikanSaldoScreen extends StatefulWidget {
  const PenarikanSaldoScreen({super.key});
  @override
  State<PenarikanSaldoScreen> createState() => _PenarikanSaldoScreenState();
}

class _PenarikanSaldoScreenState extends State<PenarikanSaldoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _service = WithdrawalService();
  final _provider = TextEditingController();
  final _account = TextEditingController();
  final _accountName = TextEditingController();
  String? _requestId;
  String _type = 'BANK';
  bool _busy = false;

  @override
  void dispose() { _amount.dispose(); _provider.dispose(); _account.dispose(); _accountName.dispose(); super.dispose(); }

  String _rp(num n) => 'Rp ${n.toStringAsFixed(0)}';

  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    final user = FirebaseAuth.instance.currentUser;
    final amount = int.tryParse(_amount.text.trim());
    if (user == null || amount == null) return;
    setState(() => _busy = true);
    try {
      final id = _requestId ??= '${DateTime.now().microsecondsSinceEpoch}_${user.uid.substring(0, user.uid.length > 8 ? 8 : user.uid.length)}';
      final result = await _service.requestWithdrawal(
        requestId: id,
        amount: amount,
        destinationType: _type,
        destinationName: _provider.text.trim(),
        destinationAccount: _account.text.trim(),
        destinationAccountName: _accountName.text.trim(),
      );
      if (!mounted) return;
      _requestId = null;
      _amount.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Permintaan ${result['status'] ?? 'PENDING'}. Saldo ditahan hingga diproses admin.')));
    } on FirebaseFunctionsException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Permintaan gagal.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permintaan gagal. Periksa riwayat sebelum mencoba lagi.')));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Penarikan Saldo')),
      body: user == null ? const Center(child: Text('Silakan login kembali.')) : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Ajukan penarikan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Saldo ditahan saat permintaan dibuat dan otomatis dikembalikan jika ditolak admin.'),
            const SizedBox(height: 16),
            TextFormField(controller: _amount, keyboardType: TextInputType.number, onChanged: (_) => _requestId = null, decoration: const InputDecoration(labelText: 'Nominal (Rp)', border: OutlineInputBorder()), validator: (v) { final n = int.tryParse((v ?? '').trim()); return n == null || n < 10000 || n > 100000000 ? 'Nominal Rp10.000–Rp100.000.000.' : null; }),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(value: _type, decoration: const InputDecoration(labelText: 'Jenis tujuan', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'BANK', child: Text('Transfer Bank')), DropdownMenuItem(value: 'E-WALLET', child: Text('E-Wallet'))], onChanged: _busy ? null : (v) => setState(() { _type = v ?? 'BANK'; _requestId = null; })),
            const SizedBox(height: 12),
            TextFormField(controller: _provider, onChanged: (_) => _requestId = null, decoration: InputDecoration(labelText: _type == 'BANK' ? 'Nama bank' : 'Nama e-wallet', border: const OutlineInputBorder()), validator: (v) => (v ?? '').trim().isEmpty ? 'Wajib diisi.' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _account, onChanged: (_) => _requestId = null, decoration: const InputDecoration(labelText: 'Nomor rekening / akun', border: OutlineInputBorder()), validator: (v) => (v ?? '').trim().isEmpty ? 'Wajib diisi.' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _accountName, onChanged: (_) => _requestId = null, decoration: const InputDecoration(labelText: 'Nama pemilik rekening / akun', border: OutlineInputBorder()), validator: (v) => (v ?? '').trim().isEmpty ? 'Wajib diisi.' : null),
            const SizedBox(height: 16),
            FilledButton(onPressed: _busy ? null : _submit, child: Text(_busy ? 'Mengirim...' : 'Ajukan Penarikan')),
          ])))),
          const SizedBox(height: 12),
          const Text('Riwayat penarikan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection('withdrawal_requests').where('uid', isEqualTo: user.uid).snapshots(), builder: (context, snapshot) {
            if (snapshot.hasError) return const ListTile(title: Text('Riwayat belum dapat dimuat.'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs.toList()..sort((a, b) { final av = a.data()['createdAt']; final bv = b.data()['createdAt']; final at = av is Timestamp ? av.millisecondsSinceEpoch : 0; final bt = bv is Timestamp ? bv.millisecondsSinceEpoch : 0; return bt.compareTo(at); });
            if (docs.isEmpty) return const ListTile(title: Text('Belum ada permintaan penarikan.'));
            return Column(children: docs.map((doc) { final d = doc.data(); final status = (d['status'] ?? 'PENDING').toString(); return Card(child: ListTile(leading: Icon(status == 'REJECTED' ? Icons.cancel : status == 'APPROVED' ? Icons.check_circle : Icons.hourglass_top), title: Text(_rp((d['amount'] as num?) ?? 0)), subtitle: Text('${d['destinationName'] ?? '-'} • ${d['destinationAccount'] ?? '-'}\n$status${d['refunded'] == true ? ' • Saldo dikembalikan' : ''}'))); }).toList());
          }),
        ],
      ),
    );
  }
}
