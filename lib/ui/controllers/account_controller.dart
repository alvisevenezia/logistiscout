import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/data/repositories/group_repository.dart';
import 'package:logistiscout/domain/entities/group.dart';

import '../../core/di.dart';

class AccountController extends AsyncNotifier<Group>{

  late final GroupRepository groupRepository;

  @override
  FutureOr<Group> build() {

    groupRepository = ref.read(groupRepositoryProvider);

    return groupRepository.getGroupInfo();

  }

}