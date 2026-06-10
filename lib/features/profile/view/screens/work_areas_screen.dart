import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/features/main/view/screens/main_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/data/models/fetch_worker_profile_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/update_worker_work_areas_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/manager/bloc/profile_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class WorkAreasScreenParams {
  final List<Zone> zones;

  WorkAreasScreenParams({required this.zones});
}

@AutoRoutePage()
class WorkAreasScreen extends StatefulWidget {
  const WorkAreasScreen({super.key, required this.params});

  final WorkAreasScreenParams params;

  @override
  State<WorkAreasScreen> createState() => _WorkAreasScreenState();
}

class _WorkAreasScreenState extends State<WorkAreasScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<_WorkAreaItem> _areas = [
    _WorkAreaItem(id: "0", name: "حلب القديمة"),
    _WorkAreaItem(id: "1", name: "الجميلية"),
    _WorkAreaItem(id: "2", name: "العزيزية"),
    _WorkAreaItem(id: "3", name: "السليمانية"),
    _WorkAreaItem(id: "4", name: "السبيل"),
    _WorkAreaItem(id: "5", name: "الموكامبو"),
    _WorkAreaItem(id: "6", name: "الفرقان"),
    _WorkAreaItem(id: "7", name: "الحمدانية"),
    _WorkAreaItem(id: "8", name: "حلب الجديدة"),
    _WorkAreaItem(id: "9", name: "الزهراء"),
    _WorkAreaItem(id: "10", name: "الخالدية"),
    _WorkAreaItem(id: "11", name: "الأشرفية"),
    _WorkAreaItem(id: "12", name: "الشيخ مقصود"),
    _WorkAreaItem(id: "13", name: "بستان القصر"),
    _WorkAreaItem(id: "14", name: "المشهد"),
    _WorkAreaItem(id: "15", name: "السكري"),
    _WorkAreaItem(id: "16", name: "الأنصاري"),
    _WorkAreaItem(id: "17", name: "صلاح الدين"),
    _WorkAreaItem(id: "18", name: "الراموسة"),
    _WorkAreaItem(id: "19", name: "العامرية"),
    _WorkAreaItem(id: "20", name: "الهلك"),
    _WorkAreaItem(id: "21", name: "الشعار"),
    _WorkAreaItem(id: "22", name: "طريق الباب"),
    _WorkAreaItem(id: "23", name: "كرم الجبل"),
    _WorkAreaItem(id: "24", name: "كرم الطراب"),
    _WorkAreaItem(id: "25", name: "كرم القاطرجي"),
    _WorkAreaItem(id: "26", name: "الميسر"),
    _WorkAreaItem(id: "27", name: "الصاخور"),
    _WorkAreaItem(id: "28", name: "الليرمون"),
    _WorkAreaItem(id: "29", name: "جمعية الزهراء"),
    _WorkAreaItem(id: "30", name: "جمعية المهندسين"),
    _WorkAreaItem(id: "31", name: "الأعظمية"),
    _WorkAreaItem(id: "32", name: "المرجة"),
    _WorkAreaItem(id: "33", name: "باب النيرب"),
    _WorkAreaItem(id: "34", name: "باب الحديد"),
    _WorkAreaItem(id: "35", name: "باب الفرج"),
    _WorkAreaItem(id: "36", name: "باب جنين"),
  ];

  List<_WorkAreaItem> filteredAreas = [];
  List<_WorkAreaItem> selectedAreas = [];
  bool get _allAreasSelected => _areas.every((area) => area.selected);

  @override
  void initState() {
    super.initState();
    for (var area in _areas) {
      if (widget.params.zones.any((zone) => zone.name == area.name)) {
        area.selected = true;
        selectedAreas.add(area);
      }
    }
    filteredAreas = List.from(_areas);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelectAllAreas() {
    setState(() {
      final shouldSelectAll = !_allAreasSelected;
      selectedAreas.clear();
      for (final area in _areas) {
        area.selected = shouldSelectAll;
        if (shouldSelectAll) {
          selectedAreas.add(area);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileBloc>(
      lazy: false,
      create: (_) => getIt<ProfileBloc>(),
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {},
        builder: (context, state) {
          return Scaffold(
            backgroundColor: const Color(0xffF3F4F6),
            body: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(context),
                  16.verticalSpace,
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsetsDirectional.symmetric(
                        horizontal: 18.w,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.r),
                          border: Border.all(color: const Color(0xffE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 16,
                              spreadRadius: -2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: EdgeInsetsDirectional.fromSTEB(
                          16.w,
                          20.h,
                          16.w,
                          16.h,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AppText.bodyLarge(
                                  'تحديد مناطق العمل',
                                  color: context.primaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                                const Spacer(),
                                Container(
                                  width: 34.w,
                                  height: 34.w,
                                  decoration: const BoxDecoration(
                                    color: Color(0xffE0F2FE),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    color: context.primaryContainer,
                                    size: 20.sp,
                                  ),
                                ),
                              ],
                            ),
                            14.verticalSpace,
                            Container(
                              width: context.width,
                              decoration: BoxDecoration(
                                color: const Color(0xffEEF2FF),
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(
                                  color: const Color(0xffA5B4FC),
                                ),
                              ),
                              padding: EdgeInsetsDirectional.symmetric(
                                horizontal: 10.w,
                                vertical: 12.h,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.lightbulb_rounded,
                                    size: 16.sp,
                                    color: const Color(0xff1E3A8A),
                                  ),
                                  6.horizontalSpace,
                                  Expanded(
                                    child: AppText.labelMedium(
                                      'تحديد مناطق العمل يساعدك على إيجاد فرص أكثر ضمن المناطق التي تود العمل ضمنها',
                                      color: const Color(0xff1E3A8A),
                                      textAlign: TextAlign.start,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            16.verticalSpace,
                            Row(
                              children: [
                                Expanded(
                                  child: AppText.bodyMedium(
                                    'اختيار المناطق',
                                    color: const Color(0xff374151),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                InkWell(
                                  onTap: _toggleSelectAllAreas,
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: Container(
                                    padding: EdgeInsetsDirectional.symmetric(
                                      horizontal: 10.w,
                                      vertical: 6.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffEFF6FF),
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(
                                        color: const Color(0xffBFDBFE),
                                      ),
                                    ),
                                    child: AppText.labelMedium(
                                      _allAreasSelected
                                          ? 'إلغاء الكل'
                                          : 'تحديد الكل',
                                      color: const Color(0xff1D4ED8),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            10.verticalSpace,
                            TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() {
                                  if (value.isEmpty) {
                                    filteredAreas = List.from(_areas);
                                  } else {
                                    filteredAreas = _areas
                                        .where(
                                          (area) => area.name.contains(value),
                                        )
                                        .toList();
                                  }
                                });
                              },
                              style: context.textTheme.labelLarge!.copyWith(
                                color: Colors.black,
                              ),
                              decoration: InputDecoration(
                                hintText: 'ابحث عن منطقة...',
                                hintStyle: TextStyle(
                                  color: const Color(0xff9CA3AF),
                                  fontSize: 14.sp,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: const Color(0xff9CA3AF),
                                  size: 20.sp,
                                ),
                                filled: true,
                                fillColor: const Color(0xffF9FAFB),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 12.h,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: const BorderSide(
                                    color: Color(0xffD1D5DB),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide(
                                    color: context.primaryContainer,
                                  ),
                                ),
                              ),
                            ),
                            14.verticalSpace,
                            if (filteredAreas.isEmpty)
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24.h),
                                  child: AppText.labelLarge(
                                    'لا توجد نتائج مطابقة',
                                    color: const Color(0xff6B7280),
                                  ),
                                ),
                              )
                            else
                              ...filteredAreas.map(_buildAreaTile),
                          ],
                        ),
                      ),
                    ),
                  ),
                  12.verticalSpace,
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      20.w,
                      0,
                      20.w,
                      14.h,
                    ),
                    child: BlocConsumer<ProfileBloc, ProfileState>(
                      listener: (context, state) {
                        if (state.updateWorkAreasStatus == BlocStatus.success) {
                          Loading.close();
                          context.pushRouteAndRemoveUntil(
                            '/main',
                            arguments: MainScreenParam(returnedPageIndex: 3),
                          );
                        } else if (state.updateWorkAreasStatus ==
                            BlocStatus.loading) {
                          Loading.show(context);
                        } else if (state.updateWorkAreasStatus ==
                            BlocStatus.failed) {
                          Loading.close();
                        }
                      },
                      builder: (context, state) {
                        return Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: InkWell(
                                onTap: () {
                                  final zones = selectedAreas
                                      .map(
                                        (e) => WorkAreaZoneUpdateItem(
                                          name: e.name,
                                          isActive: e.selected,
                                        ),
                                      )
                                      .toList();
                                  context.read<ProfileBloc>().add(
                                    UpdateWorkerWorkAreasEvent(
                                      params: UpdateWorkerWorkAreasParams(
                                        zones: zones,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.r),
                                    color: context.primary,
                                  ),
                                  padding: EdgeInsetsDirectional.symmetric(
                                    horizontal: 12.w,
                                    vertical: 8.h,
                                  ),
                                  child: AppText.labelLarge(
                                    'حفظ التغييرات',
                                    color: context.onPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            10.horizontalSpace,
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  context.pop();
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.r),
                                    color: context.error.withAlpha(50),
                                    border: Border.all(color: context.error),
                                  ),
                                  padding: EdgeInsetsDirectional.symmetric(
                                    horizontal: 6.w,
                                    vertical: 8.h,
                                  ),
                                  child: AppText.labelLarge(
                                    'إلغاء',
                                    color: context.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      width: context.width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
        border: Border(
          bottom: BorderSide(color: context.primaryContainer, width: 2),
        ),
      ),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: 22.w,
        vertical: 16.h,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              context.pop();
            },
            child: Icon(
              Icons.arrow_back_ios_new,
              color: context.primaryContainer,
            ),
          ),
          10.horizontalSpace,
          AppText.headlineLarge(
            'مناطق العمل',
            color: context.primaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }

  Widget _buildAreaTile(_WorkAreaItem item) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: () {
          setState(() {
            item.selected = !item.selected;
            if (item.selected) {
              selectedAreas.add(item);
            } else {
              selectedAreas.removeWhere((element) => element.id == item.id);
            }
          });
        },
        child: Container(
          width: context.width,
          decoration: BoxDecoration(
            color: item.selected
                ? const Color(0xffE0F2F1)
                : const Color(0xffF9FAFB),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: item.selected
                  ? context.primaryContainer
                  : const Color(0xffE5E7EB),
            ),
          ),
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: 10.w,
            vertical: 10.h,
          ),
          child: Row(
            children: [
              _SelectionBox(isSelected: item.selected),
              10.horizontalSpace,
              Expanded(
                child: AppText.bodySmall(
                  item.name,
                  color: const Color(0xff111827),
                  fontWeight: FontWeight.w700,
                  textAlign: TextAlign.start,
                ),
              ),
              Container(
                width: 34.w,
                height: 34.w,
                decoration: const BoxDecoration(
                  color: Color(0xffF3F4F6),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 18.sp,
                  color: item.selected
                      ? context.primaryContainer
                      : const Color(0xffD1D5DB),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionBox extends StatelessWidget {
  const _SelectionBox({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22.w,
      height: 22.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.r),
        color: isSelected ? context.primaryContainer : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? context.primaryContainer
              : const Color(0xffC7CDD4),
          width: 1.7,
        ),
      ),
      child: isSelected
          ? Icon(Icons.check_rounded, color: Colors.white, size: 16.sp)
          : null,
    );
  }
}

class _WorkAreaItem {
  _WorkAreaItem({required this.id, required this.name});

  final String id;
  final String name;
  bool selected = false;
}
