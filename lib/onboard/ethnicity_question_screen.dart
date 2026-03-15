import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/onboard/map.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widgets/button_widget.dart';
import '../../widgets/text_widget.dart';

enum EthnicityFlowStep { ethnicity, datingGoal, sexuality }

class EthnicityQuestionScreen extends StatefulWidget {
  const EthnicityQuestionScreen({super.key});

  @override
  State<EthnicityQuestionScreen> createState() =>
      _EthnicityQuestionScreenState();
}

class _EthnicityQuestionScreenState extends State<EthnicityQuestionScreen>
    with TickerProviderStateMixin {
  final flow = Get.find<AppFlowController>();
  late final AnimationController _controller;

  EthnicityFlowStep step = EthnicityFlowStep.ethnicity;
  String? selected;

  final datingGoalOptions = const [
    "Long-term",
    "Casual",
    "Friends",
    "Prefer not to say",
  ];

  final sexualityOptions = const [
    "Straight",
    "Bisexual",
    "Asexual",
    "Demisexual",
    "Queer",
    "Gay",
    "Lesbian",
    "Prefer not to say",
  ];

  final ethnicityGroups = const <String, List<Map<String, String>>>{
    "East Asian": [
      {"flag": "🇨🇳", "country": "China"},
      {"flag": "🇭🇰", "country": "Hong Kong"},
      {"flag": "🇯🇵", "country": "Japan"},
      {"flag": "🇰🇷", "country": "South Korea"},
      {"flag": "🇹🇼", "country": "Taiwan"},
      {"flag": "🇲🇴", "country": "Macau"},
      {"flag": "🇲🇳", "country": "Mongolia"},
    ],
    "Southeast Asian": [
      {"flag": "🇰🇭", "country": "Cambodia"},
      {"flag": "🇻🇳", "country": "Vietnam"},
      {"flag": "🇹🇭", "country": "Thailand"},
      {"flag": "🇵🇭", "country": "Philippines"},
      {"flag": "🇱🇦", "country": "Laos"},
      {"flag": "🇲🇾", "country": "Malaysia"},
      {"flag": "🇮🇩", "country": "Indonesia"},
      {"flag": "🇸🇬", "country": "Singapore"},
      {"flag": "🇲🇲", "country": "Myanmar"},
      {"flag": "🇧🇳", "country": "Brunei"},
      {"flag": "🇹🇱", "country": "Timor-Leste"},
    ],
    "South Asian": [
      {"flag": "🇮🇳", "country": "India"},
      {"flag": "🇵🇰", "country": "Pakistan"},
      {"flag": "🇧🇩", "country": "Bangladesh"},
      {"flag": "🇱🇰", "country": "Sri Lanka"},
      {"flag": "🇳🇵", "country": "Nepal"},
      {"flag": "🇧🇹", "country": "Bhutan"},
      {"flag": "🇲🇻", "country": "Maldives"},
    ],
    "White / Caucasian": [
      {"flag": "🇦🇹", "country": "Austria"},
      {"flag": "🇧🇪", "country": "Belgium"},
      {"flag": "🇩🇰", "country": "Denmark"},
      {"flag": "🇫🇮", "country": "Finland"},
      {"flag": "🇫🇷", "country": "France"},
      {"flag": "🇩🇪", "country": "Germany"},
      {"flag": "🇮🇹", "country": "Italy"},
      {"flag": "🇳🇱", "country": "Netherlands"},
      {"flag": "🇳🇴", "country": "Norway"},
      {"flag": "🇵🇱", "country": "Poland"},
      {"flag": "🇵🇹", "country": "Portugal"},
      {"flag": "🇪🇸", "country": "Spain"},
      {"flag": "🇸🇪", "country": "Sweden"},
      {"flag": "🇨🇭", "country": "Switzerland"},
      {"flag": "🇬🇧", "country": "United Kingdom"},
    ],
    "Hispanic / Latino": [
      {"flag": "🇲🇽", "country": "Mexico"},
      {"flag": "🇵🇷", "country": "Puerto Rico"},
      {"flag": "🇨🇺", "country": "Cuba"},
      {"flag": "🇩🇴", "country": "Dominican Republic"},
      {"flag": "🇨🇴", "country": "Colombia"},
      {"flag": "🇻🇪", "country": "Venezuela"},
      {"flag": "🇵🇪", "country": "Peru"},
      {"flag": "🇨🇱", "country": "Chile"},
      {"flag": "🇦🇷", "country": "Argentina"},
      {"flag": "🇪🇨", "country": "Ecuador"},
      {"flag": "🇸🇻", "country": "El Salvador"},
      {"flag": "🇬🇹", "country": "Guatemala"},
      {"flag": "🇭🇳", "country": "Honduras"},
      {"flag": "🇳🇮", "country": "Nicaragua"},
      {"flag": "🇵🇦", "country": "Panama"},
      {"flag": "🇧🇴", "country": "Bolivia"},
    ],
    "African / Caribbean": [
      {"flag": "🇳🇬", "country": "Nigeria"},
      {"flag": "🇪🇹", "country": "Ethiopia"},
      {"flag": "🇰🇪", "country": "Kenya"},
      {"flag": "🇬🇭", "country": "Ghana"},
      {"flag": "🇿🇦", "country": "South Africa"},
      {"flag": "🇸🇳", "country": "Senegal"},
      {"flag": "🇯🇲", "country": "Jamaica"},
      {"flag": "🇭🇹", "country": "Haiti"},
      {"flag": "🇹🇹", "country": "Trinidad & Tobago"},
      {"flag": "🇧🇧", "country": "Barbados"},
    ],
    "Pacific Islander": [
      {"flag": "🇼🇸", "country": "Samoa"},
      {"flag": "🇹🇴", "country": "Tonga"},
      {"flag": "🇫🇯", "country": "Fiji"},
      {"flag": "🇲🇭", "country": "Marshall Islands"},
      {"flag": "🇫🇲", "country": "Micronesia"},
      {"flag": "🇵🇼", "country": "Palau"},
      {"flag": "🇻🇺", "country": "Vanuatu"},
      {"flag": "🇬🇺", "country": "Guam"},
    ],
    "Other": [
      {"flag": "🌍", "country": "Mixed / Multiracial"},
      {"flag": "✍️", "country": "Self-describe"},
    ],
  };

  bool get isValid => selected != null && selected!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _controller.forward();
    });

    if (flow.ethnicity.value == null || flow.ethnicity.value!.isEmpty) {
      step = EthnicityFlowStep.ethnicity;
      selected = flow.ethnicity.value;
    } else if (flow.datingGoal.value == null ||
        flow.datingGoal.value!.isEmpty) {
      step = EthnicityFlowStep.datingGoal;
      selected = flow.datingGoal.value;
    } else {
      step = EthnicityFlowStep.sexuality;
      selected = flow.sexuality.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _animated(Widget child, double from, double to) {
    final anim = CurvedAnimation(
      parent: _controller,
      curve: Interval(from, to, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, (1 - anim.value) * 28),
          child: child,
        ),
      ),
    );
  }

  Widget _topHeader(BuildContext context) {
    final stepIndex = step == EthnicityFlowStep.ethnicity
        ? 0
        : step == EthnicityFlowStep.datingGoal
            ? 1
            : 2;

    return SizedBox(
      height: 7.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 62.w,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (7 + stepIndex) / 11,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFFFD6DE),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFF3B7A)),
                  ),
                ),
              ),
              SizedBox(height: 0.8.h),
              TextWidget(
                text: '${8 + stepIndex} of 11',
                size: 12,
                color: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    final isSelected = selected == text;
    return GestureDetector(
      onTap: () => setState(() => selected = text),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.7.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFECEF) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6F7D) : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: TextWidget(
          text: text,
          weight: FontWeight.w600,
          color: isSelected ? const Color(0xFFFF6F7D) : const Color(0xFF1E1E1E),
        ),
      ),
    );
  }

  Widget _countryTile(String group, String flag, String country) {
    final value = "$group • $country";
    final isSelected = selected == value;

    return GestureDetector(
      onTap: () => setState(() => selected = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.2.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFECEF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6F7D) : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: TextStyle(fontSize: 18.sp)),
            SizedBox(height: 0.6.h),
            TextWidget(
              text: country,
              size: 13,
              weight: FontWeight.w600,
              color: isSelected
                  ? const Color(0xFFFF6F7D)
                  : const Color(0xFF1E1E1E),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _ethnicityGrid() {
    final children = <Widget>[];

    ethnicityGroups.forEach((group, items) {
      children.add(
        Padding(
          padding: EdgeInsets.only(top: 2.h, bottom: 1.h),
          child: TextWidget(text: group, size: 16, weight: FontWeight.w700),
        ),
      );

      children.add(
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 1.2.h,
          crossAxisSpacing: 2.w,
          childAspectRatio: 1.05,
          children: items
              .map((e) => _countryTile(group, e["flag"]!, e["country"]!))
              .toList(),
        ),
      );
    });

    return SingleChildScrollView(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Future<void> _continue() async {
    if (!isValid) return;

    if (step == EthnicityFlowStep.ethnicity) {
      flow.ethnicity.value = selected;
      step = EthnicityFlowStep.datingGoal;
      selected = flow.datingGoal.value;
      setState(() {});
      await flow.saveOnboardingProgress();
      return;
    }

    if (step == EthnicityFlowStep.datingGoal) {
      flow.datingGoal.value = selected;
      step = EthnicityFlowStep.sexuality;
      selected = flow.sexuality.value;
      setState(() {});
      await flow.saveOnboardingProgress();
      return;
    }

    flow.sexuality.value = selected;
    await flow.saveOnboardingProgress();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LocationQuestionScreen()),
    );
  }

  String get _title {
    switch (step) {
      case EthnicityFlowStep.ethnicity:
        return "What’s your ethnic background?";
      case EthnicityFlowStep.datingGoal:
        return "What are you looking for?";
      case EthnicityFlowStep.sexuality:
        return "How do you identify?";
    }
  }

  String get _subtitle {
    switch (step) {
      case EthnicityFlowStep.ethnicity:
        return "Select one — you can always edit this later.";
      case EthnicityFlowStep.datingGoal:
        return "Be honest. It helps matches feel right.";
      case EthnicityFlowStep.sexuality:
        return "Share what feels accurate for you.";
    }
  }

  Widget _content() {
    if (step == EthnicityFlowStep.ethnicity) return _ethnicityGrid();

    final options = step == EthnicityFlowStep.datingGoal
        ? datingGoalOptions
        : sexualityOptions;

    return SingleChildScrollView(
      child: Wrap(
        spacing: 3.w,
        runSpacing: 1.4.h,
        children: options.map(_pill).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 1.h),
                _animated(_topHeader(context), 0, 0.15),
                SizedBox(height: 3.h),
                _animated(
                  TextWidget(
                      text: _title, size: 18.sp, weight: FontWeight.w500),
                  0.15,
                  0.3,
                ),
                SizedBox(height: 0.8.h),
                _animated(
                  TextWidget(text: _subtitle, size: 15, color: Colors.grey),
                  0.2,
                  0.35,
                ),
                SizedBox(height: 2.h),
                _animated(_content(), 0.35, 0.9),
                SizedBox(height: 2.h),
                _animated(
                  ButtonWidget(
                    text: step == EthnicityFlowStep.sexuality
                        ? 'Next'
                        : 'Continue',
                    height: 7,
                    radius: 36,
                    variant:
                        isValid ? ButtonVariant.gradient : ButtonVariant.solid,
                    gradient: const [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                    backgroundColor: Colors.grey.shade300,
                    enableShadow: isValid,
                    onTap: isValid ? _continue : () {},
                  ),
                  0.9,
                  1,
                ),
                SizedBox(height: 3.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
