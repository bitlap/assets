import '../models/asset_account.dart';
import '../models/asset_flat_item.dart';

(int, int) findSectionRange(List<AssetFlatItem> items, AssetType type) {
  int start = -1;
  int end = items.length;
  for (int i = 0; i < items.length; i++) {
    if (items[i] is SectionHeader) {
      final h = items[i] as SectionHeader;
      if (h.type == type) {
        start = i;
      } else if (start >= 0 && end == items.length) {
        end = i;
        break;
      }
    }
  }
  return (start, end);
}

List<AssetType> reorderSectionOrder(
  List<AssetType> sectionOrder,
  List<AssetFlatItem> flatItems,
  AssetType type,
  int oldIndex,
  int newIndex,
) {
  final oldSectionIdx = sectionOrder.indexOf(type);
  int targetSectionIdx = 0;
  for (int i = 0; i < newIndex; i++) {
    final origIdx = i < oldIndex ? i : i + 1;
    if (origIdx >= flatItems.length) break;
    if (flatItems[origIdx] is SectionHeader) targetSectionIdx++;
  }
  if (oldSectionIdx == targetSectionIdx) return sectionOrder;

  final order = List<AssetType>.from(sectionOrder);
  order.removeAt(oldSectionIdx);
  order.insert(targetSectionIdx, type);
  for (final t in AssetType.values) {
    if (!order.contains(t)) {
      order.add(t);
    }
  }
  return order;
}

int computeSameTypeCount(
  List<AssetFlatItem> flatItems,
  AssetType type,
  int oldIndex,
  int newIndex,
) {
  int count = 0;
  for (int i = 0; i < newIndex; i++) {
    final origIdx = i < oldIndex ? i : i + 1;
    if (origIdx >= flatItems.length) break;
    final fi = flatItems[origIdx];
    if (fi is AssetCardItem && fi.asset.type == type) {
      count++;
    }
  }
  return count;
}

List<AssetBase> reorderAssets(
  List<AssetBase> assets,
  AssetBase item,
  AssetType type,
  int sameTypeCount,
) {
  final newAssets = List<AssetBase>.from(assets)
    ..removeAt(assets.indexOf(item));

  int insertAt = newAssets.length;
  int typeCount = 0;
  for (int i = 0; i < newAssets.length; i++) {
    if (newAssets[i].type == type) {
      if (typeCount == sameTypeCount) {
        insertAt = i;
        break;
      }
      typeCount++;
    }
  }
  if (insertAt == newAssets.length && typeCount > 0) {
    for (int i = newAssets.length - 1; i >= 0; i--) {
      if (newAssets[i].type == type) {
        insertAt = i + 1;
        break;
      }
    }
  }
  newAssets.insert(insertAt, item);
  return newAssets;
}
