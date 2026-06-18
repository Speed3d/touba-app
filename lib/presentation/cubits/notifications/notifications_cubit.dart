import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/services/notification_service.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final _service = NotificationService.instance;
  StreamSubscription? _sub;

  NotificationsCubit() : super(NotificationsInitial());

  void startListening() {
    _sub?.cancel();
    _sub = _service.getNotificationsStream().listen(
      (list) => emit(NotificationsLoaded(list)),
      onError: (e) => emit(NotificationsError(e.toString())),
    );
  }

  Future<void> markAsRead(String id) => _service.markAsRead(id);
  Future<void> markAllAsRead() => _service.markAllAsRead();
  Future<void> deleteNotification(String id) => _service.deleteNotification(id);

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
