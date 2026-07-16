// ... (Bagian import tetap sama)

class _HomeScreenState extends State<HomeScreen> {
  final SaldoService _saldoService = SaldoService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  
  bool _isSaldoHidden = false;
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6F9), // Warna background premium
      body: StreamBuilder<int>( // Mengaktifkan kembali real-time saldo
        stream: _saldoService.streamSaldo(_currentUser?.uid ?? ""),
        builder: (context, snapshot) {
          final saldo = snapshot.data ?? 0;
          return _buildBody(saldo);
        }
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody(int saldo) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: const Color(0xFF0054A6),
          flexibleSpace: FlexibleSpaceBar(
            background: _buildHeaderContent(saldo),
          ),
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildCoreServices(),
              _buildBantuanBanner(),
              _buildDealsSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderContent(int saldo) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF0054A6), Color(0xFF007BE6)]),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("DesaPay Premium", style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.2)),
              IconButton(onPressed: (){}, icon: const Icon(Icons.notifications_none, color: Colors.white))
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text("Rp", style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(width: 8),
              Text(_isSaldoHidden ? "••••••" : _formatRupiah(saldo), 
                   style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
              IconButton(
                onPressed: () => setState(() => _isSaldoHidden = !_isSaldoHidden), 
                icon: Icon(_isSaldoHidden ? Icons.visibility_off : Icons.visibility, color: Colors.white54, size: 20)
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCoreServices() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 20,
        children: [
          _menuItem(Icons.phone_android, "Pulsa", const Color(0xFF0054A6)),
          _menuItem(Icons.bolt, "Listrik", const Color(0xFFFFB300)),
          _menuItem(Icons.water_drop, "PDAM", const Color(0xFF00C4FF)),
          _menuItem(Icons.health_and_safety, "BPJS", const Color(0xFF22C55E)),
          _menuItem(Icons.tv, "TV Kabel", const Color(0xFF8338EC)),
          _menuItem(Icons.flight, "Tiket", const Color(0xFFFF6600)),
          _menuItem(Icons.gamepad, "Games", const Color(0xFFE11D48)),
          _menuItem(Icons.apps, "Lainnya", Colors.grey),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).moveY(begin: 20, end: 0);
  }

  Widget _menuItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
      ],
    );
  }

  // Helper untuk format Rupiah
  String _formatRupiah(int number) {
    return number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  // ... (Sisa fungsi lain seperti _buildBantuanBanner dan _buildBottomNav tetap sama namun Anda bisa perbaiki warnanya agar senada)
}
