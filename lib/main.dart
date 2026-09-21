import 'package:flutter/material.dart';

void main() {
  runApp(const ItHelperApp());
}

/// ----------------------------------------------------------------------
/// App root
/// ----------------------------------------------------------------------
class ItHelperApp extends StatelessWidget {
  const ItHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IT Helper',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
      ),
      home: const MainShell(),
    );
  }
}

/// ----------------------------------------------------------------------
/// Decision-tree data model
/// ----------------------------------------------------------------------
class Node {
  final String title;
  final String description;
  final String question;
  final String? command;
  final String? tip;
  final Node? yes;
  final Node? no;
  final bool solved;

  const Node({
    required this.title,
    required this.description,
    required this.question,
    this.command,
    this.tip,
    this.yes,
    this.no,
    this.solved = false,
  });
}

/// Convenience constructor for a terminal (result) node.
Node end(String title, String description) {
  return Node(
    title: title,
    description: description,
    question: 'نتیجه',
    solved: true,
  );
}

class Scenario {
  final String title;
  final String icon;
  final String category;
  final Node root;

  const Scenario(this.title, this.icon, this.category, this.root);
}

/// ----------------------------------------------------------------------
/// Scenario builders — each function returns one fully built tree.
/// Built bottom-up with named locals so nesting stays easy to read/verify.
/// ----------------------------------------------------------------------

Scenario _buildNoInternet() {
  final dnsOk = end(
    'احتمال مشکل مرورگر یا Proxy',
    'DNS پاسخ می‌دهد؛ Proxy، VPN، مرورگر و تنظیمات امنیتی را بررسی کن.',
  );
  final dnsBad = end(
    'احتمال مشکل DNS',
    'DNS سیستم یا DHCP را بررسی و سپس تست را تکرار کن.',
  );
  final checkDns = Node(
    title: 'DNS را بررسی کن',
    description: 'اگر IP جواب می‌دهد ولی سایت‌ها باز نمی‌شوند، DNS را بررسی کن.',
    command: 'nslookup google.com',
    question: 'آیا پاسخ DNS دریافت شد؟',
    yes: dnsOk,
    no: dnsBad,
  );

  final internetBad = end(
    'ارتباط اینترنت مشکل دارد',
    'مودم/روتر، کابل WAN و وضعیت سرویس اینترنت را بررسی کن.',
  );
  final checkInternet = Node(
    title: 'اتصال اینترنت را تست کن',
    description: 'ارتباط با یک IP عمومی را بررسی کن.',
    command: 'ping 8.8.8.8',
    question: 'آیا Reply دریافت شد؟',
    yes: checkDns,
    no: internetBad,
  );

  final gatewayBad = end(
    'ارتباط با Gateway مشکل دارد',
    'IP، Subnet Mask، Gateway، کابل، VLAN و اتصال به Switch/Access Point را بررسی کن.',
  );
  final checkGateway = Node(
    title: 'Gateway را تست کن',
    description: 'Default Gateway را از خروجی ipconfig پیدا کن.',
    command: 'ping <Default-Gateway>',
    question: 'آیا Reply دریافت شد؟',
    yes: checkInternet,
    no: gatewayBad,
  );

  final dhcpFixed = end('IP دریافت شد', 'حالا Gateway و اینترنت را دوباره تست کن.');
  final dhcpBad = end(
    'DHCP یا کارت شبکه را بررسی کن',
    'DHCP Server، Scope، VLAN و تنظیمات Network Adapter را بررسی کن.',
  );
  final checkDhcp = Node(
    title: 'DHCP را بررسی کن',
    description: 'احتمال مشکل DHCP یا Network Adapter وجود دارد.',
    command: 'ipconfig /release\nipconfig /renew',
    question: 'بعد از Renew، IP دریافت شد؟',
    yes: dhcpFixed,
    no: dhcpBad,
  );

  final checkIp = Node(
    title: 'آدرس IP را بررسی کن',
    description: 'Win + R را بزن، cmd را باز کن و دستور زیر را اجرا کن.',
    command: 'ipconfig',
    question: 'آیا IPv4 Address دریافت کرده‌ای؟',
    tip: 'اگر IP شبیه 169.254.x.x است، احتمال مشکل DHCP وجود دارد.',
    yes: checkGateway,
    no: checkDhcp,
  );

  final physicalBad = end(
    'اتصال فیزیکی را بررسی کن',
    'کابل، چراغ Link، Wi‑Fi، مودم و Access Point را بررسی کن.',
  );
  final root = Node(
    title: 'اتصال شبکه را بررسی کن',
    description: 'مطمئن شو کابل شبکه وصل است یا Wi‑Fi روشن و متصل است.',
    question: 'اتصال شبکه برقرار است؟',
    yes: checkIp,
    no: physicalBad,
  );

  return Scenario('اینترنت وصل نیست', '🌐', 'شبکه', root);
}

Scenario _buildWifiDrops() {
  final fixed = end('مشکل برطرف شد', 'اتصال Wi‑Fi پایدار شد.');
  final stillBad = end(
    'تنظیمات شبکه را بررسی کن',
    'درایور Wi‑Fi، کانال، DHCP و تنظیمات Access Point را بررسی کن.',
  );
  final reconnect = Node(
    title: 'اتصال را دوباره برقرار کن',
    description: 'Wi‑Fi را خاموش و روشن کن و دوباره به شبکه متصل شو.',
    question: 'مشکل برطرف شد؟',
    yes: fixed,
    no: stillBad,
  );

  final weakSignal = end(
    'سیگنال ضعیف است',
    'نزدیک‌تر شو، محل Access Point را بررسی کن و موانع را کاهش بده.',
  );
  final root = Node(
    title: 'قدرت سیگنال را بررسی کن',
    description: 'فاصله با مودم یا Access Point و موانع فیزیکی را بررسی کن.',
    question: 'سیگنال مناسب است؟',
    yes: reconnect,
    no: weakSignal,
  );

  return Scenario('Wi‑Fi قطع و وصل می‌شود', '📶', 'شبکه', root);
}

Scenario _buildSlowComputer() {
  final foundApp = end(
    'برنامه مشکل‌ساز پیدا شد',
    'برنامه را ببند یا علت اجرای آن را بررسی کن.',
  );
  final noAppFound = end(
    'منابع سیستم را بررسی کن',
    'Startup، Windows Update، فضای دیسک و وضعیت RAM/SSD را بررسی کن.',
  );
  final findApp = Node(
    title: 'برنامه مصرف‌کننده را پیدا کن',
    description: 'در Processes مرتب‌سازی را بر اساس CPU، Memory یا Disk انجام بده.',
    question: 'برنامه غیرضروری پیدا شد؟',
    yes: foundApp,
    no: noAppFound,
  );

  final generalCheck = end(
    'بررسی‌های تکمیلی',
    'Startup، فضای دیسک، Windows Update و وضعیت SSD/HDD را بررسی کن.',
  );
  final root = Node(
    title: 'Task Manager را باز کن',
    description: 'با Ctrl + Shift + Esc میزان CPU، RAM و Disk را بررسی کن.',
    question: 'یکی از منابع نزدیک 100٪ است؟',
    yes: findApp,
    no: generalCheck,
  );

  return Scenario('کامپیوتر کند شده', '🐌', 'ویندوز', root);
}

Scenario _buildPrinterIssue() {
  final printAgain = end('دوباره چاپ بگیر', 'یک Print Test Page بگیر.');
  final driverIssue = end(
    'Driver و سرویس چاپ را بررسی کن',
    'Printer Driver، Print Spooler و Default Printer را بررسی کن.',
  );
  final checkQueue = Node(
    title: 'صف چاپ را بررسی کن',
    description: 'Printer Queue را باز کن و چاپ‌های گیرکرده را بررسی یا پاک کن.',
    question: 'صف چاپ خالی شد؟',
    yes: printAgain,
    no: driverIssue,
  );

  final connectionBad = end(
    'اتصال پرینتر را اصلاح کن',
    'کابل، Wi‑Fi، IP پرینتر و چراغ‌های وضعیت را بررسی کن.',
  );
  final root = Node(
    title: 'اتصال پرینتر را بررسی کن',
    description: 'کابل USB یا اتصال Wi‑Fi و روشن بودن دستگاه را بررسی کن.',
    question: 'پرینتر متصل و روشن است؟',
    yes: checkQueue,
    no: connectionBad,
  );

  return Scenario('پرینتر کار نمی‌کند', '🖨️', 'پرینتر', root);
}

Scenario _buildBlackScreen() {
  final checkCableAgain = end(
    'نمایشگر یا کابل را بررسی کن',
    'کابل، ورودی مانیتور و GPU را دقیق‌تر بررسی کن.',
  );
  final hardwareIssue = end(
    'عیب‌یابی سخت‌افزاری',
    'RAM، GPU، PSU، CMOS و کدهای بوق/POST را بررسی کن.',
  );
  final checkPost = Node(
    title: 'RAM و GPU را بررسی کن',
    description: 'اگر با سخت‌افزار آشنایی داری، RAM و کارت گرافیک و اتصالات برق را بررسی کن.',
    question: 'سیستم POST می‌کند؟',
    yes: checkCableAgain,
    no: hardwareIssue,
  );

  final fixed = end('مشکل برطرف شد', 'اتصال تصویر برقرار شد.');
  final root = Node(
    title: 'برق و کابل تصویر',
    description: 'برق مانیتور، کابل HDMI/DP و ورودی صحیح تصویر را بررسی کن.',
    question: 'تصویر برگشت؟',
    yes: fixed,
    no: checkPost,
  );

  return Scenario('صفحه سیاه است', '🖥️', 'سخت‌افزار', root);
}

Scenario _buildCannotLogin() {
  final groupPolicy = end(
    'Group Policy و Credential را بررسی کن',
    'Cached Credentials، Password Expiration و Group Policy را بررسی کن.',
  );
  final domainBad = end(
    'اتصال Domain مشکل دارد',
    'شبکه، DNS و دسترسی به Domain Controller را بررسی کن.',
  );
  final checkDomain = Node(
    title: 'اتصال به Domain را بررسی کن',
    description: 'اگر سیستم Domain Joined است، اتصال به Domain Controller و وضعیت Credential را بررسی کن.',
    question: 'اتصال Domain برقرار است؟',
    yes: groupPolicy,
    no: domainBad,
  );

  final accountBad = end(
    'اکانت را اصلاح کن',
    'Password، Account Lockout، Disabled Account و Credential ذخیره‌شده را بررسی کن.',
  );
  final root = Node(
    title: 'وضعیت حساب را بررسی کن',
    description: 'نام کاربری، رمز عبور، قفل یا غیرفعال بودن Account را بررسی کن.',
    question: 'Account فعال و اطلاعات ورود صحیح است؟',
    yes: checkDomain,
    no: accountBad,
  );

  return Scenario('وارد ویندوز نمی‌شوم', '🔐', 'اکانت', root);
}

Scenario _buildNoSound() {
  final settingsOk = end(
    'تنظیمات صدا را بررسی کن',
    'Mute، Volume Mixer و برنامه موردنظر را بررسی کن.',
  );
  final driverBad = end('Driver صدا را اصلاح کن', 'Driver را Update یا در صورت نیاز Reinstall کن.');
  final checkDriver = Node(
    title: 'Driver صدا را بررسی کن',
    description: 'Device Manager را باز کن و Audio Driver را بررسی کن.',
    question: 'Driver سالم است؟',
    yes: settingsOk,
    no: driverBad,
  );

  final outputBad = end(
    'Output Device را اصلاح کن',
    'اسپیکر یا Headset صحیح را به‌عنوان خروجی انتخاب کن.',
  );
  final root = Node(
    title: 'Output Device را بررسی کن',
    description: 'Volume و دستگاه خروجی صدا را در Windows بررسی کن.',
    question: 'خروجی صحیح انتخاب شده؟',
    yes: checkDriver,
    no: outputBad,
  );

  return Scenario('صدا ندارم', '🔊', 'ویندوز', root);
}

Scenario _buildSiteNotOpening() {
  final siteSpecific = end(
    'احتمال مشکل همان سایت',
    'وضعیت سرور یا محدودیت‌های همان سایت را بررسی کن.',
  );
  final dnsBad = end('مشکل DNS', 'DNS را تغییر/اصلاح کن و دوباره تست بگیر.');
  final checkDns = Node(
    title: 'DNS و مرورگر را بررسی کن',
    description: 'Cache، DNS، Proxy و VPN را بررسی کن.',
    command: 'nslookup example.com',
    question: 'DNS پاسخ می‌دهد؟',
    yes: siteSpecific,
    no: dnsBad,
  );

  final checkInternetFirst = end(
    'ابتدا اتصال اینترنت را بررسی کن',
    'سناریوی «اینترنت وصل نیست» را اجرا کن.',
  );
  final root = Node(
    title: 'آیا سایت دیگری باز می‌شود؟',
    description: 'یک سایت شناخته‌شده دیگر را امتحان کن.',
    question: 'سایت‌های دیگر باز می‌شوند؟',
    yes: checkDns,
    no: checkInternetFirst,
  );

  return Scenario('سایت باز نمی‌شود', '🌍', 'مرورگر', root);
}

final List<Scenario> scenarios = <Scenario>[
  _buildNoInternet(),
  _buildWifiDrops(),
  _buildSlowComputer(),
  _buildPrinterIssue(),
  _buildBlackScreen(),
  _buildCannotLogin(),
  _buildNoSound(),
  _buildSiteNotOpening(),
];

/// ----------------------------------------------------------------------
/// App shell / navigation
/// ----------------------------------------------------------------------
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  final List<String> recent = [];

  void _openScenario(BuildContext context, Scenario scenario) {
    setState(() => recent.insert(0, scenario.title));
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TroubleshootPage(scenario: scenario)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(onOpen: (s) => _openScenario(context, s)),
      const ToolsPage(),
      HistoryPage(items: recent),
      const ProfilePage(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: pages[index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => setState(() => index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'خانه'),
            NavigationDestination(icon: Icon(Icons.handyman_outlined), selectedIcon: Icon(Icons.handyman), label: 'ابزارها'),
            NavigationDestination(icon: Icon(Icons.history), label: 'تاریخچه'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'پروفایل'),
          ],
        ),
      ),
    );
  }
}

/// ----------------------------------------------------------------------
/// Home page
/// ----------------------------------------------------------------------
class HomePage extends StatefulWidget {
  final ValueChanged<Scenario> onOpen;
  const HomePage({super.key, required this.onOpen});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final shown = scenarios
        .where((s) => s.title.contains(query) || s.category.contains(query))
        .toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.build_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('IT Helper', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                          Text('دستیار عیب‌یابی کامپیوتر', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('مشکل کامپیوترت رو بگو؛', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
                  const Text('قدم‌به‌قدم حلش کن.', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 14),
                  TextField(
                    onChanged: (v) => setState(() => query = v),
                    decoration: InputDecoration(
                      hintText: 'مثلاً: اینترنت ندارم',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: const Icon(Icons.mic_none_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text('مشکل من اینه که…', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (c, i) {
                  final s = shown[i];
                  return InkWell(
                    onTap: () => widget.onOpen(s),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE5EAF1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(s.icon, style: const TextStyle(fontSize: 28)),
                          const SizedBox(height: 8),
                          Text(s.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(s.category, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                        ],
                      ),
                    ),
                  );
                },
                childCount: shown.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)]),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 30),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('عیب‌یابی هوشمند', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                          SizedBox(height: 4),
                          Text('هر پاسخ، مسیر بعدی را مشخص می‌کند.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ----------------------------------------------------------------------
/// Tools page
/// ----------------------------------------------------------------------
class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('ابزارهای IT', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('ابزارهای کاربردی برای عیب‌یابی سریع‌تر', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          ToolCard(
            icon: '🌐',
            title: 'Subnet Calculator',
            desc: 'محاسبه Network، Broadcast و محدوده IP',
            onTap: () => showDialog(
              context: context,
              builder: (_) => const SimpleToolDialog(
                title: 'Subnet Calculator',
                text: 'نسخه حرفه‌ای این ابزار در مرحله بعد اضافه می‌شود.',
              ),
            ),
          ),
          ToolCard(
            icon: '🔎',
            title: 'DNS Lookup',
            desc: 'راهنمای بررسی و تست DNS',
            onTap: () => showDialog(
              context: context,
              builder: (_) => const SimpleToolDialog(
                title: 'DNS Lookup',
                text: 'برای تست سریع می‌توانی از nslookup استفاده کنی.',
              ),
            ),
          ),
          ToolCard(
            icon: '📡',
            title: 'Ping',
            desc: 'راهنمای تست Gateway و Internet',
            onTap: () => showDialog(
              context: context,
              builder: (_) => const SimpleToolDialog(title: 'Ping', text: 'مثال: ping 8.8.8.8'),
            ),
          ),
          ToolCard(
            icon: '🔌',
            title: 'Port Guide',
            desc: 'آشنایی سریع با پورت‌های رایج',
            onTap: () => showDialog(
              context: context,
              builder: (_) => const SimpleToolDialog(
                title: 'Port Guide',
                text: 'HTTP: 80   HTTPS: 443   DNS: 53   SSH: 22',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ToolCard extends StatelessWidget {
  final String icon;
  final String title;
  final String desc;
  final VoidCallback onTap;

  const ToolCard({
    super.key,
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(14),
        leading: Text(icon, style: const TextStyle(fontSize: 30)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(desc),
        trailing: const Icon(Icons.chevron_left),
      ),
    );
  }
}

class SimpleToolDialog extends StatelessWidget {
  final String title;
  final String text;

  const SimpleToolDialog({super.key, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(text),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('باشه')),
      ],
    );
  }
}

/// ----------------------------------------------------------------------
/// History page
/// ----------------------------------------------------------------------
class HistoryPage extends StatelessWidget {
  final List<String> items;
  const HistoryPage({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('تاریخچه عیب‌یابی', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(child: Text('هنوز عیب‌یابی‌ای انجام نداده‌ای.')),
            )
          else
            ...items.map(
              (x) => Card(
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(x),
                  subtitle: const Text('شروع شده'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// ----------------------------------------------------------------------
/// Profile page
/// ----------------------------------------------------------------------
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('پروفایل', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF111827), Color(0xFF334155)]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('IT Helper Pro', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                SizedBox(height: 8),
                Text('بدون تبلیغات + ابزارهای حرفه‌ای + سناریوهای پیشرفته', style: TextStyle(color: Colors.white70)),
                SizedBox(height: 16),
                Text('به‌زودی', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('درباره برنامه'),
            subtitle: Text('دستیار عیب‌یابی مرحله‌به‌مرحله IT Helper'),
          ),
        ],
      ),
    );
  }
}

/// ----------------------------------------------------------------------
/// Troubleshoot flow page
/// ----------------------------------------------------------------------
class TroubleshootPage extends StatefulWidget {
  final Scenario scenario;
  const TroubleshootPage({super.key, required this.scenario});

  @override
  State<TroubleshootPage> createState() => _TroubleshootPageState();
}

class _TroubleshootPageState extends State<TroubleshootPage> {
  late Node current;
  int step = 1;
  final List<Node> history = <Node>[];

  @override
  void initState() {
    super.initState();
    current = widget.scenario.root;
  }

  void answer(bool value) {
    if (current.solved) return;
    final next = value ? current.yes : current.no;
    if (next == null) return;
    history.add(current);
    setState(() {
      current = next;
      step++;
    });
  }

  void backStep() {
    if (history.isEmpty) return;
    setState(() {
      current = history.removeLast();
      step = step > 1 ? step - 1 : 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.scenario.title), backgroundColor: Colors.transparent),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('مرحله $step', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w900)),
                    const Spacer(),
                    if (history.isNotEmpty)
                      TextButton.icon(
                        onPressed: backStep,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('مرحله قبل'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(minHeight: 7, value: current.solved ? 1 : null),
                ),
                const SizedBox(height: 24),
                Text(current.title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Text(current.description, style: const TextStyle(fontSize: 16, height: 1.75)),
                if (current.tip != null)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, color: Color(0xFF2563EB)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(current.tip!, style: const TextStyle(fontSize: 13, height: 1.5))),
                      ],
                    ),
                  ),
                if (current.command != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SelectableText(
                      current.command!,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 15),
                    ),
                  ),
                ],
                const Spacer(),
                if (current.solved) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8EF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 10),
                        Expanded(child: Text(current.title, style: const TextStyle(fontWeight: FontWeight.w800))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('بازگشت به مشکلات'),
                      ),
                    ),
                  ),
                ] else ...[
                  Text(current.question, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => answer(true),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            child: Text('بله'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => answer(false),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            child: Text('خیر'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
