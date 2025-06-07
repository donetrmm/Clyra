import 'package:flutter/foundation.dart';

enum ViewState { idle, loading, error, success }

abstract class BaseViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String _errorMessage = '';

  ViewState get state => _state;
  String get errorMessage => _errorMessage;

  bool get isLoading => _state == ViewState.loading;
  bool get hasError => _state == ViewState.error;
  bool get isSuccess => _state == ViewState.success;
  bool get isIdle => _state == ViewState.idle;

  void setState(ViewState newState) {
    _state = newState;
    notifyListeners();
  }

  void setLoading() {
    setState(ViewState.loading);
  }

  void setSuccess() {
    setState(ViewState.success);
  }

  void setError(String message) {
    _errorMessage = message;
    setState(ViewState.error);
  }

  void setIdle() {
    _errorMessage = '';
    setState(ViewState.idle);
  }

  Future<void> runAsyncOperation(Future<void> Function() operation) async {
    try {
      setLoading();
      await operation();
      setSuccess();
    } catch (e) {
      setError(e.toString());
    }
  }
}
