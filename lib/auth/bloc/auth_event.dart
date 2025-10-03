import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}


// Student authentication events
class StudentSignInRequested extends AuthEvent {
  final String regNo;

  const StudentSignInRequested({
    required this.regNo,
  });

  @override
  List<Object?> get props => [regNo];
}

// Legacy events (keeping for backward compatibility)
class AuthSignUpRequested extends AuthEvent {
  final String regNo;
  final String email;
  final String password;
  final String level;
  final String gender;

  const AuthSignUpRequested({
    required this.regNo,
    required this.email,
    required this.password,
    required this.level,
    required this.gender,
  });

  @override
  List<Object?> get props => [regNo, email, password, level, gender];
}

class AuthSignInRequested extends AuthEvent {
  final String regNo;
  final String password;

  const AuthSignInRequested({
    required this.regNo,
    required this.password,
  });

  @override
  List<Object?> get props => [regNo, password];
}

class AuthSignOutRequested extends AuthEvent {}
