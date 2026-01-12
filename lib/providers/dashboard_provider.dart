import 'package:flutter_riverpod/flutter_riverpod.dart';

// Dashboard state model
class DashboardState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic> data;

  const DashboardState({
    this.isLoading = false,
    this.error,
    this.data = const {},
  });

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? data,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      data: data ?? this.data,
    );
  }
}

// Dashboard notifier with Notifier
class DashboardNotifier extends Notifier<DashboardState> {
  @override
  DashboardState build() => const DashboardState();
  
  Future<void> loadDashboardData() async {
    state = const DashboardState(isLoading: true, error: null);
    
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      state = const DashboardState(
        isLoading: false,
        data: {
          'totalProjects': 12,
          'activeProjects': 8,
          'completedProjects': 4,
          'totalDeliverables': 45,
          'completedDeliverables': 32,
          'pendingDeliverables': 13,
        },
      );
    } catch (e) {
      state = DashboardState(
        isLoading: false,
        error: 'Failed to load dashboard data: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Riverpod provider setup
final dashboardStateProvider = NotifierProvider<DashboardNotifier, DashboardState>(() {
  return DashboardNotifier();
});
