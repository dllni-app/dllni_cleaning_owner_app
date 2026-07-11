import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/features/main/navigation/main_tab_navigation.dart';
import 'package:dllni_cleaninig_owner_app/features/main/view/screens/main_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/data/models/cleaning_neighborhood_model.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/data/models/fetch_worker_profile_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_cleaning_neighborhoods_use_case.dart';
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

  List<_WorkAreaItem> _areas = [];
  List<_WorkAreaItem> filteredAreas = [];
  List<_WorkAreaItem> selectedAreas = [];

  bool get _allAreasSelected =>
      _areas.isNotEmpty && _areas.every((area) => area.selected);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyNeighborhoods(List<CleaningNeighborhoodModel> neighborhoods) {
    _areas = neighborhoods
        .map((n) {
          final alreadySelected = widget.params.zones.any(
            (zone) => zone.neighborhoodId == n.id || zone.name == n.displayName,
          );
          return _WorkAreaItem(
            neighborhoodId: n.id,
            name: n.displayName,
            selected: alreadySelected,
          );
        })
        .toList(growable: false);
    selectedAreas = _areas.where((area) => area.selected).toList();
    filteredAreas = _filterAreas(_searchController.text);
  }

  List<_WorkAreaItem> _filterAreas(String query) {
    final normalized = query.trim();
    if (normalized.isEmpty) return List<_WorkAreaItem>.from(_areas);
    return _areas
        .where((area) => area.name.contains(normalized))
        .toList(growable: false);
  }

  void _fetchNeighborhoods(BuildContext context) {
    context.read<ProfileBloc>().add(
      FetchCleaningNeighborhoodsEvent(
        params: FetchCleaningNeighborhoodsParams(city: 'حلب'),
      ),
    );
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

  void _onSave(BuildContext context) {
    if (selectedAreas.isEmpty) {
      AppToast.showErrorGlobal(
        'يرجى اختيار حي واحد على الأقل حتى تصلك الطلبات المناسبة.',
      );
      return;
    }

    final zones = selectedAreas
        .map(
          (e) => WorkAreaZoneUpdateItem(
            neighborhoodId: e.neighborhoodId,
            name: e.name,
            isActive: e.selected,
          ),
        )
        .toList();

    context.read<ProfileBloc>().add(
      UpdateWorkerWorkAreasEvent(
        params: UpdateWorkerWorkAreasParams(zones: zones),
      ),
    );
  }

  Widget _buildAreasContent(ProfileState state) {
    if (state.cleaningNeighborhoodsStatus == BlocStatus.loading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 32.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.cleaningNeighborhoodsStatus == BlocStatus.failed) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        child: Column(
          children: [
            AppText.labelLarge(
              state.cleaningNeighborhoodsErrorMessage ??
                  'تعذر تحميل الأحياء، حاول مرة أخرى',
              color: const Color(0xff6B7280),
              textAlign: TextAlign.center,
            ),
            12.verticalSpace,
            InkWell(
              onTap: () => _fetchNeighborhoods(context),
              borderRadius: BorderRadius.circular(8.r),
              child: Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: 14.w,
                  vertical: 8.h,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffEFF6FF),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: const Color(0xffBFDBFE)),
                ),
                child: AppText.labelMedium(
                  'إعادة المحاولة',
                  color: const Color(0xff1D4ED8),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_areas.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          child: AppText.labelLarge(
            'لا توجد أحياء متاحة حالياً',
            color: const Color(0xff6B7280),
          ),
        ),
      );
    }

    if (filteredAreas.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          child: AppText.labelLarge(
            'لا توجد نتائج مطابقة',
            color: const Color(0xff6B7280),
          ),
        ),
      );
    }

    return Column(
      children: filteredAreas.map(_buildAreaTile).toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileBloc>(
      lazy: false,
      create: (_) {
        final bloc = getIt<ProfileBloc>();
        bloc.add(
          FetchCleaningNeighborhoodsEvent(
            params: FetchCleaningNeighborhoodsParams(city: 'حلب'),
          ),
        );
        return bloc;
      },
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listenWhen: (previous, current) =>
            previous.cleaningNeighborhoodsStatus !=
                current.cleaningNeighborhoodsStatus ||
            previous.cleaningNeighborhoods != current.cleaningNeighborhoods,
        buildWhen: (previous, current) =>
            previous.cleaningNeighborhoodsStatus !=
                current.cleaningNeighborhoodsStatus ||
            previous.cleaningNeighborhoods != current.cleaningNeighborhoods ||
            previous.cleaningNeighborhoodsErrorMessage !=
                current.cleaningNeighborhoodsErrorMessage ||
            previous.updateWorkAreasStatus != current.updateWorkAreasStatus,
        listener: (context, state) {
          if (state.cleaningNeighborhoodsStatus == BlocStatus.success &&
              state.cleaningNeighborhoods != null) {
            setState(() => _applyNeighborhoods(state.cleaningNeighborhoods!));
          }
        },
        builder: (context, state) {
          final neighborhoodsLoaded =
              state.cleaningNeighborhoodsStatus == BlocStatus.success &&
              _areas.isNotEmpty;
          final canSave =
              neighborhoodsLoaded &&
              state.updateWorkAreasStatus != BlocStatus.loading;

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
                                  onTap: _areas.isEmpty
                                      ? null
                                      : _toggleSelectAllAreas,
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
                              enabled: _areas.isNotEmpty,
                              onChanged: (value) {
                                setState(() {
                                  filteredAreas = _filterAreas(value);
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
                            _buildAreasContent(state),
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
                      listenWhen: (previous, current) =>
                          previous.updateWorkAreasStatus !=
                          current.updateWorkAreasStatus,
                      buildWhen: (previous, current) =>
                          previous.updateWorkAreasStatus !=
                          current.updateWorkAreasStatus,
                      listener: (context, state) {
                        if (state.updateWorkAreasStatus == BlocStatus.success) {
                          Loading.close();
                          final opened = MainTabNavigation.instance.jumpToTab(
                            3,
                          );
                          if (!opened) {
                            context.pushRouteAndRemoveUntil(
                              '/main',
                              arguments: MainScreenParam(returnedPageIndex: 3),
                            );
                          }
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
                                onTap: canSave ? () => _onSave(context) : null,
                                child: Opacity(
                                  opacity: canSave ? 1 : 0.5,
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
              if (!selectedAreas.contains(item)) {
                selectedAreas.add(item);
              }
            } else {
              selectedAreas.removeWhere(
                (element) => element.neighborhoodId == item.neighborhoodId,
              );
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
  _WorkAreaItem({
    required this.neighborhoodId,
    required this.name,
    this.selected = false,
  });

  final int neighborhoodId;
  final String name;
  bool selected;
}
