import 'dart:typed_data';

import 'package:logistiscout/domain/entities/issue.dart';
import 'package:logistiscout/domain/entities/item.dart';
import 'package:logistiscout/services/api_service.dart';

/// Matériel hors tentes et signalements (tentes comprises).
class ItemRepository {
  final ApiService api;

  ItemRepository(this.api);

  Future<List<ItemType>> getItemTypes() async {
    final json = await api.getItemTypes();
    return json
        .map((e) => ItemType.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Item>> getItems() async {
    final json = await api.getItems();
    return json.map((e) => Item.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Item> createItem(Item item) async {
    return Item.fromJson(await api.createItem(item.toJson()));
  }

  Future<Item> updateItem(Item item) async {
    return Item.fromJson(await api.updateItem(item.id, item.toJson()));
  }

  Future<void> deleteItem(int id) => api.deleteItem(id);

  Future<List<Issue>> getIssues({IssueTarget? target, IssueState? state}) async {
    final json = await api.getIssues(
      targetKind: target?.kind.jsonValue,
      targetId: target?.id,
      state: state?.jsonValue,
    );
    return json.map((e) => Issue.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Issue> createIssue({
    required IssueTarget target,
    required String description,
    required bool usable,
    int quantity = 1,
    String? reporterName,
  }) async {
    final json = await api.createIssue({
      'targetKind': target.kind.jsonValue,
      'targetId': target.id,
      'description': description,
      'usable': usable,
      'quantity': quantity,
      'reporterName': reporterName,
    });
    return Issue.fromJson(json);
  }

  Future<Issue> setIssueState(int issueId, IssueState state) async {
    return Issue.fromJson(
      await api.updateIssue(issueId, {'state': state.jsonValue}),
    );
  }

  Future<Issue> uploadIssuePicture({
    required int issueId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    return Issue.fromJson(
      await api.uploadIssuePicture(
        issueId: issueId,
        bytes: bytes,
        fileName: fileName,
      ),
    );
  }
}
