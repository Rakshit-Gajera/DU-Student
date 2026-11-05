import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../async_view.dart';
import '../common.dart';
import '../demo_data.dart';
import '../format.dart';
import '../models/student_models.dart';
import '../providers/student_provider.dart';
import '../ui_kit.dart';

/// Layout follows the Transport Summary screen. Always marked as a sample:
/// this demo must not be usable as a real bus pass.
class TransportScreen extends ConsumerWidget {
  const TransportScreen({super.key, this.fixedTime});
  final DateTime? fixedTime;

  @override
  Widget build(BuildContext context, WidgetRef ref) => DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: const Color(0xFFF4F4F6),
          appBar: const BlackAppBar('Transport Summary',
              centerTitle: true,
              trailing: Padding(
                padding: EdgeInsets.only(right: 12),
                child: Text('Pay Fees', style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900)),
              )),
          body: Column(children: [
            Container(
              color: Colors.white,
              width: double.infinity,
              child: TextTabs(tabs: [
                const Tab(text: 'Bus Pass'),
                Tab(
                  child: Row(children: [
                    const Text('Receipt'),
                    if (ref.watch(busReceiptsProvider).asData?.value case final receipts?) ...[
                      const SizedBox(width: 6),
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: const Color(0xFF555B70),
                        child: Text('${receipts.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400)),
                      ),
                    ],
                  ]),
                ),
              ]),
            ),
            Expanded(
              child: TabBarView(children: [
                AsyncBody(
                  value: ref.watch(transportProvider),
                  onRetry: () {
                    ref.invalidate(profileProvider);
                    ref.invalidate(transportProvider);
                  },
                  skeleton: const SkeletonList(count: 1, height: 420),
                  builder: (data) => data.$2.isEmpty
                      ? const EmptyText('No Bus Pass Found')
                      : ListView(children: [
                          for (final pass in data.$2) _PassCard(pass: pass, profile: data.$1),
                          _Clock(fixedTime: fixedTime),
                        ]),
                ),
                AsyncBody(
                  value: ref.watch(busReceiptsProvider),
                  onRetry: () => ref.invalidate(busReceiptsProvider),
                  builder: (receipts) => receipts.isEmpty
                      ? const EmptyText('No Receipts Found')
                      : ListView(padding: const EdgeInsets.fromLTRB(9, 8, 9, 8), children: [for (final r in receipts) _receipt(r)]),
                ),
              ]),
            ),
          ]),
        ),
      );
}

Widget _receipt(BusReceipt r) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: cardDecoration(radius: 7),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            DateChip(calendarDate(r.paidOn)),
            const SizedBox(height: 4),
            Text(r.receiptNo, style: hv(15.5)),
            if (r.description != null) Text(r.description!, style: bd(13, const Color(0xFF555555))),
          ]),
        ),
        Text('₹ ${r.amount}', style: hv(17, AppColors.green)),
      ]),
    );

class _PassCard extends StatelessWidget {
  const _PassCard({required this.pass, required this.profile});
  final BusPass pass;
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    const label = TextStyle(fontSize: 13.5, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900, color: Colors.black);
    const value = TextStyle(fontSize: 16, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400, color: Colors.black);
    return Container(
      margin: const EdgeInsets.fromLTRB(9, 5, 7, 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        image: DecorationImage(image: AssetImage(img('bg_bus_pass.jpg')), fit: BoxFit.cover),
      ),
      child: Stack(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(9, 6, 0, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _photo(),
              ),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Image.asset(img('bus_pass_bus_2.png'), width: 58, height: 45, fit: BoxFit.contain),
                    const SizedBox(width: 12),
                    pass.active ? _pill('Active', AppColors.green) : _pill('Inactive', AppColors.grey),
                  ]),
                  const SizedBox(height: 10),
                  _pill('Bus Pass No. ${pass.passNo}', const Color(0xFFF26A32)),
                ]),
              ),
            ]),
            const SizedBox(height: 10),
            Text(profile.name, style: const TextStyle(fontSize: 16.5, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400, color: Colors.black)),
            const SizedBox(height: 3),
            Text('(Sem- ${profile.currentSem} | ${profile.mobile ?? '-'} | ${pass.batchCode ?? profile.classLabel})', style: const TextStyle(fontSize: 15.5, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400, color: Colors.black)),
            const SizedBox(height: 14),
            const Text('Pickup Point', style: label),
            const SizedBox(height: 4),
            Text(pass.pickupPoint ?? '-', style: value),
            if (pass.pickupAddress != null) ...[
              const SizedBox(height: 14),
              const Text('Pickup Address', style: label),
              const SizedBox(height: 4),
              Text(pass.pickupAddress!, style: value),
            ],
            const SizedBox(height: 14),
            const Text('Shift & Timings', style: label),
            const SizedBox(height: 4),
            Text(pass.shift ?? '-', style: value),
            const SizedBox(height: 14),
            const Text('Route', style: label),
            const SizedBox(height: 4),
            Text(pass.busRoute, style: value),
            if (pass.busCode != null) ...[
              const SizedBox(height: 14),
              const Text('Bus Code', style: label),
              const SizedBox(height: 4),
              Text(pass.busCode!, style: value),
            ],
            const SizedBox(height: 14),
            Row(children: [
              _fee('Fees Amount', '₹ ${pass.feesAmount}', AppColors.blue),
              const SizedBox(width: 28),
              _fee('Fees Paid', '₹ ${pass.feesPaid}', AppColors.green),
              const SizedBox(width: 18),
              _fee('Pending Amount', '₹ ${pass.pending}', Colors.black),
            ]),
          ]),
        ),
        const Positioned.fill(child: IgnorePointer(child: _SampleMark())),
      ]),
    );
  }

  Widget _photo() {
    Widget bundled() => Image.asset(demoPhoto, width: 103, height: 96, fit: BoxFit.cover);
    final url = profile.photoUrl;
    if (url == null || url.isEmpty) return bundled();
    return Image.network(resolveApiUrl(url), width: 103, height: 96, fit: BoxFit.cover, errorBuilder: (_, _, _) => bundled());
  }

  Widget _pill(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: c,
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
        ),
        child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900)),
      );

  Widget _fee(String t, String v, Color c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t, style: const TextStyle(fontSize: 12.5, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900, color: Colors.black)),
        const SizedBox(height: 4),
        Text(v, style: TextStyle(fontSize: 17, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400, color: c)),
      ]);
}

class _SampleMark extends StatelessWidget {
  const _SampleMark();

  @override
  Widget build(BuildContext context) => Center(
        child: Transform.rotate(
          angle: -math.pi / 7,
          child: Text('SAMPLE',
              style: TextStyle(
                  fontSize: 64,
                  fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400,
                  letterSpacing: 6,
                  color: AppColors.red.withValues(alpha: .28))),
        ),
      );
}

class _Clock extends StatefulWidget {
  const _Clock({this.fixedTime});
  final DateTime? fixedTime;

  @override
  State<_Clock> createState() => _ClockState();
}

class _ClockState extends State<_Clock> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    if (widget.fixedTime == null) {
      _t = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  String _pad(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final n = widget.fixedTime ?? DateTime.now();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(children: [
        Text('${_pad(n.day)}-${_pad(n.month)}-${n.year}',
            style: const TextStyle(fontSize: 14, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400, color: Color(0xFF1E2646))),
        Text('${_pad(n.hour)}:${_pad(n.minute)}:${_pad(n.second)}',
            style: const TextStyle(fontSize: 50, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400, color: Color(0xFF1E2646), height: 1.1, letterSpacing: -1)),
      ]),
    );
  }
}
