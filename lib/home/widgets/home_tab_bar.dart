import 'package:fcleaner/home/cubit/home_cubit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeTabBar extends StatelessWidget {
  const HomeTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedTab = context.select<HomeCubit, HomeTab>(
      (cubit) => cubit.state.selectedTab,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<HomeTab>(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        groupValue: selectedTab,
        onValueChanged: (value) {
          context.read<HomeCubit>().selectTab(value);
        },
        children: const {
          HomeTab.overview: Text(
            'Overview',
            style: TextStyle(fontSize: 14),
          ),
          HomeTab.cleanup: Text(
            'System Cleanup',
            style: TextStyle(fontSize: 14),
          ),
          HomeTab.uninstall: Text(
            'Uninstall',
            style: TextStyle(fontSize: 14),
          ),
        },
      ),
    );
  }
}
