import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/features/auth/domain/account.dart';
import 'package:university_messenger/features/services/domain/service_models.dart';
import 'package:university_messenger/features/services/presentation/service_strings.dart';
import 'package:university_messenger/features/services/presentation/service_widgets.dart';
import 'package:university_messenger/features/services/services_providers.dart';
import 'package:university_messenger/features/services/services_routes.dart';

class ServicesHomeScreen extends ConsumerStatefulWidget {
  const ServicesHomeScreen({super.key});

  @override
  ConsumerState<ServicesHomeScreen> createState() => _ServicesHomeScreenState();
}

class _ServicesHomeScreenState extends ConsumerState<ServicesHomeScreen> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    ref.watch(serviceRealtimeSyncProvider);
    final role = ref.watch(authControllerProvider).state.account?.role;
    if (role == UserRole.staff) return const StaffQueueScreen();
    if (role != UserRole.student) {
      return const Scaffold(
        appBar: _ServicesAppBar(title: ServiceStrings.services),
        body: ServiceEmptyState(
          icon: Icons.lock_outline_rounded,
          title: ServiceStrings.services,
          body: ServiceStrings.unsupportedRole,
        ),
      );
    }

    final wide = MediaQuery.sizeOf(context).width >= 760;
    final pages = [
      const ServiceCatalogScreen(),
      StudentRequestListScreen(
        onBrowseCatalog: () => setState(() => _selectedIndex = 0),
      ),
    ];
    final destinations = const [
      NavigationRailDestination(
        icon: Icon(Icons.widgets_outlined),
        selectedIcon: Icon(Icons.widgets_rounded),
        label: Text(ServiceStrings.serviceCatalog),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long_rounded),
        label: Text(ServiceStrings.myRequests),
      ),
    ];
    return Scaffold(
      appBar: const _ServicesAppBar(title: ServiceStrings.services),
      body: SafeArea(
        top: false,
        child: wide
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    labelType: NavigationRailLabelType.all,
                    destinations: destinations,
                    onDestinationSelected: (index) =>
                        setState(() => _selectedIndex = index),
                  ),
                  VerticalDivider(
                    width: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  Expanded(
                    child: IndexedStack(index: _selectedIndex, children: pages),
                  ),
                ],
              )
            : IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.widgets_outlined),
                  selectedIcon: Icon(Icons.widgets_rounded),
                  label: ServiceStrings.serviceCatalog,
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: ServiceStrings.myRequests,
                ),
              ],
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
            ),
    );
  }
}

class ServiceCatalogScreen extends ConsumerWidget {
  const ServiceCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(serviceCatalogProvider);
    return catalog.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ServiceErrorState(
        title: ServiceStrings.loadServicesError,
        error: error,
        onRetry: () => ref.invalidate(serviceCatalogProvider),
      ),
      data: (services) {
        if (services.isEmpty) {
          return const ServiceEmptyState(
            icon: Icons.widgets_outlined,
            title: ServiceStrings.noServices,
            body: ServiceStrings.noServicesBody,
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(serviceCatalogProvider.future),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 12),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    ServiceStrings.serviceCatalog,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 32),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 420,
                    mainAxisExtent: 190,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ServiceCatalogItem(
                      service: services[index],
                      onTap: () => context.push(
                        ServiceRoutes.newRequest(services[index].id),
                      ),
                    ),
                    childCount: services.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ServiceCatalogItem extends StatelessWidget {
  const _ServiceCatalogItem({required this.service, required this.onTap});

  final ServiceType service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.description_outlined, color: scheme.primary),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: scheme.onSurfaceVariant,
                    textDirection: Directionality.of(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                service.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  service.description ?? ServiceStrings.fieldHelp,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (service.slaHours != null)
                Text(
                  '${ServiceStrings.estimatedTime}: ${service.slaHours} ${ServiceStrings.hours}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: scheme.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentRequestListScreen extends ConsumerWidget {
  const StudentRequestListScreen({this.onBrowseCatalog, super.key});

  final VoidCallback? onBrowseCatalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(serviceRequestsProvider);
    final catalog = ref.watch(serviceCatalogProvider).valueOrNull ?? const [];
    return requests.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ServiceErrorState(
        title: ServiceStrings.loadRequestsError,
        error: error,
        onRetry: () => ref.invalidate(serviceRequestsProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return ServiceEmptyState(
            icon: Icons.receipt_long_outlined,
            title: ServiceStrings.noRequests,
            body: ServiceStrings.noRequestsBody,
            action: FilledButton.icon(
              onPressed:
                  onBrowseCatalog ?? () => context.push(ServiceRoutes.root),
              icon: const Icon(Icons.add_rounded),
              label: const Text(ServiceStrings.newRequest),
            ),
          );
        }
        return _RequestList(
          title: ServiceStrings.myRequests,
          requests: items,
          catalog: catalog,
          onRefresh: () => ref.refresh(serviceRequestsProvider.future),
          onTap: (request) =>
              context.push(ServiceRoutes.requestDetail(request.id)),
        );
      },
    );
  }
}

class StaffQueueScreen extends ConsumerStatefulWidget {
  const StaffQueueScreen({super.key});

  @override
  ConsumerState<StaffQueueScreen> createState() => _StaffQueueScreenState();
}

class _StaffQueueScreenState extends ConsumerState<StaffQueueScreen> {
  var _tab = 0;
  String? _claimingId;

  Future<void> _claim(ServiceRequest request) async {
    setState(() => _claimingId = request.id);
    try {
      await ref.read(servicesApiProvider).claim(request.id);
      ref.invalidate(serviceRequestsProvider);
      ref.invalidate(serviceRequestDetailProvider(request.id));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(ServiceStrings.claimed)));
      await context.push(ServiceRoutes.requestDetail(request.id));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(serviceErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _claimingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(serviceRequestsProvider);
    final catalog = ref.watch(serviceCatalogProvider).valueOrNull ?? const [];
    return Scaffold(
      appBar: const _ServicesAppBar(title: ServiceStrings.staffQueue),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 8),
              child: SegmentedButton<int>(
                expandedInsets: EdgeInsets.zero,
                segments: const [
                  ButtonSegment(
                    value: 0,
                    icon: Icon(Icons.inbox_outlined),
                    label: Text(ServiceStrings.available),
                  ),
                  ButtonSegment(
                    value: 1,
                    icon: Icon(Icons.assignment_ind_outlined),
                    label: Text(ServiceStrings.assignedToMe),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (value) =>
                    setState(() => _tab = value.first),
              ),
            ),
            Expanded(
              child: requests.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ServiceErrorState(
                  title: ServiceStrings.loadRequestsError,
                  error: error,
                  onRetry: () => ref.invalidate(serviceRequestsProvider),
                ),
                data: (items) {
                  final filtered = items
                      .where(
                        (request) => _tab == 0
                            ? !request.isAssigned
                            : request.isAssigned,
                      )
                      .toList();
                  if (filtered.isEmpty) {
                    return ServiceEmptyState(
                      icon: _tab == 0
                          ? Icons.inbox_outlined
                          : Icons.assignment_ind_outlined,
                      title: _tab == 0
                          ? ServiceStrings.noQueue
                          : ServiceStrings.noAssigned,
                      body: _tab == 0
                          ? ServiceStrings.noQueueBody
                          : ServiceStrings.noAssignedBody,
                    );
                  }
                  return _RequestList(
                    requests: filtered,
                    catalog: catalog,
                    onRefresh: () =>
                        ref.refresh(serviceRequestsProvider.future),
                    onTap: (request) => request.isAssigned
                        ? context.push(ServiceRoutes.requestDetail(request.id))
                        : _claim(request),
                    trailing: (request) => request.isAssigned
                        ? const Icon(Icons.arrow_forward_rounded)
                        : FilledButton.tonal(
                            onPressed: _claimingId == null
                                ? () => _claim(request)
                                : null,
                            child: _claimingId == request.id
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(ServiceStrings.claim),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  const _RequestList({
    required this.requests,
    required this.catalog,
    required this.onRefresh,
    required this.onTap,
    this.title,
    this.trailing,
  });

  final List<ServiceRequest> requests;
  final List<ServiceType> catalog;
  final Future<void> Function() onRefresh;
  final ValueChanged<ServiceRequest> onTap;
  final String? title;
  final Widget Function(ServiceRequest request)? trailing;

  @override
  Widget build(BuildContext context) {
    final names = {for (final service in catalog) service.id: service.name};
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 32),
        itemCount: requests.length + (title == null ? 0 : 1),
        separatorBuilder: (_, index) => index == 0 && title != null
            ? const SizedBox(height: 12)
            : Divider(color: Theme.of(context).colorScheme.outlineVariant),
        itemBuilder: (context, index) {
          if (title != null && index == 0) {
            return Padding(
              padding: const EdgeInsetsDirectional.only(start: 8, bottom: 6),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            );
          }
          final request = requests[index - (title == null ? 0 : 1)];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: const Icon(Icons.description_outlined),
            ),
            title: Text(
              names[request.serviceTypeId] ?? ServiceStrings.unknownService,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ServiceStatusChip(status: request.status),
                Text(formatServiceDate(context, request.updatedAt)),
              ],
            ),
            trailing:
                trailing?.call(request) ??
                const Icon(Icons.arrow_forward_rounded),
            onTap: () => onTap(request),
          );
        },
      ),
    );
  }
}

class _ServicesAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ServicesAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(title: Text(title));
}
