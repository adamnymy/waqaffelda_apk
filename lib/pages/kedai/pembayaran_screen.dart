import 'package:flutter/material.dart';
import '../../../services/cart_service.dart';
import '../../../widgets/kedai_widgets.dart';

class PembayaranScreen extends StatefulWidget {
  const PembayaranScreen({super.key});

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  final _nameController =
      TextEditingController(text: 'Ahmad Faiz bin Hassan');
  final _phoneController =
      TextEditingController(text: '012-345 6789');
  final _addressController = TextEditingController(
      text: 'No. 12, Jalan Felda Sungai Tekam,\n28300 Triang, Pahang');

  String _selectedPayment = 'fpx';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KedaiColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                children: [
                  _buildShippingCard(),
                  const SizedBox(height: 16),
                  _buildPaymentCard(),
                ],
              ),
            ),
          ),
          _buildPayButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return KedaiGradientHeader(
      height: 115,
      child: Row(
        children: [
          const KedaiBackArrowButton(),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'LANGKAH 2 / 2',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Pembayaran',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildShippingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KedaiColors.borderLight),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: KedaiColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_on_outlined,
                    color: KedaiColors.primaryDarker, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Maklumat Penghantaran',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: KedaiColors.textPrimary,
                  )),
            ],
          ),
          const SizedBox(height: 16),
          _label('NAMA PENUH'),
          const SizedBox(height: 6),
          _textField(_nameController),
          const SizedBox(height: 14),
          _label('NO. TELEFON'),
          const SizedBox(height: 6),
          _textField(_phoneController,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 14),
          _label('ALAMAT PENGHANTARAN'),
          const SizedBox(height: 6),
          _textField(_addressController, maxLines: 2),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: KedaiColors.textSecondary,
        letterSpacing: 1,
      ),
    );
  }

  Widget _textField(TextEditingController controller,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(
          fontSize: 14, color: KedaiColors.textPrimary),
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: KedaiColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: KedaiColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: KedaiColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KedaiColors.borderLight),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: KedaiColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.credit_card_outlined,
                    color: KedaiColors.primaryDarker, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Kaedah Pembayaran',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: KedaiColors.textPrimary,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          _paymentOption(
            id: 'fpx',
            title: 'FPX / Perbankan Dalam Talian',
            subtitle: 'Maybank2u, CIMB Clicks, dll',
            recommended: true,
          ),
          const SizedBox(height: 8),
          _paymentOption(
            id: 'card',
            title: 'Kad Kredit / Debit',
            subtitle: 'Visa, Mastercard',
          ),
          const SizedBox(height: 8),
          _paymentOption(
            id: 'ewallet',
            title: 'e-Dompet',
            subtitle: "Touch 'n Go, GrabPay, Boost",
          ),
        ],
      ),
    );
  }

  Widget _paymentOption({
    required String id,
    required String title,
    required String subtitle,
    bool recommended = false,
  }) {
    final selected = _selectedPayment == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? KedaiColors.primaryLight.withOpacity(0.4)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? KedaiColors.primary : KedaiColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      selected ? KedaiColors.primary : KedaiColors.border,
                  width: 2,
                ),
                color: Colors.white,
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: KedaiColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: KedaiColors.textPrimary,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12,
                          color: KedaiColors.textSecondary)),
                ],
              ),
            ),
            if (recommended)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: KedaiColors.accentLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'DISYORKAN',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: KedaiColors.accent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayButton() {
    final total = CartService.instance.total;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, -4))
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _showPaymentSuccess(total),
          style: ElevatedButton.styleFrom(
            backgroundColor: KedaiColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Bayar Sekarang',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'RM${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentSuccess(double total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: KedaiColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: KedaiColors.primary, size: 40),
              ),
              const SizedBox(height: 18),
              const Text('Pembayaran Berjaya!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: KedaiColors.textPrimary,
                  )),
              const SizedBox(height: 6),
              Text(
                'Terima kasih atas sumbangan anda. Pesanan RM${total.toStringAsFixed(2)} sedang diproses.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13,
                    color: KedaiColors.textSecondary,
                    height: 1.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    CartService.instance.clear();
                    Navigator.of(ctx).pop();
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KedaiColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Kembali ke Kedai',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
