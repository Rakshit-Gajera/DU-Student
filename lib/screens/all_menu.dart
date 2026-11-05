import 'package:flutter/material.dart';

import '../common.dart';
import '../demo_data.dart';
import 'dashboard.dart';

class AllMenuScreen extends StatelessWidget {
  const AllMenuScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const BlackAppBar('All Menu'),
        body: Column(children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(7, 12, 7, 10),
            child: Row(children: [
              Expanded(child: SearchField()),
              SizedBox(width: 8),
              Icon(Icons.filter_list, size: 26, color: Colors.black87),
              SizedBox(width: 6),
            ]),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 7),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 3),
                itemCount: allMenu.length,
                itemExtent: 55.4,
                itemBuilder: (context, i) => InkWell(
                  onTap: () => openMenu(context, allMenu[i].title),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(children: [
                      Image.asset(img(allMenu[i].icon), width: 29, height: 29, color: tintFor(allMenu[i].title)),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(allMenu[i].title,
                            style: const TextStyle(fontSize: 18.5, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400, color: Colors.black)),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.grey, size: 24),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ]),
      );
}
