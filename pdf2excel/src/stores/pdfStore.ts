import { defineStore } from "pinia";
import { computed, ref } from "vue";
import { parseAmount } from "@/lib/utils";

export interface OrderItem {
  id: string;
  日期: string;
  客户名: string;
  订单号: string;
  零件号: string;
  零件描述: string;
  数量: string;
  价格: string;
  金额: string;
  计划交货日期: string;
  订单交期: string;
}

export interface PdfInfo {
  orderNo: string;
  supplierNo: string;
  supplierName: string;
  customerName: string;
  currency: string;
}

export type DisplayItem = OrderItem & {
  _mergeCount?: number;
};

function formatNumber(value: number, decimals: number): string {
  if (!Number.isFinite(value)) return "0";
  return value.toFixed(decimals);
}

function getQtyLabel(item: OrderItem): string {
  const raw = item.数量?.trim();
  if (raw) return raw;
  return formatNumber(parseAmount(item.数量), 2);
}

function formatMergedDates(items: OrderItem[], field: "计划交货日期" | "订单交期"): string {
  const dates = items.map((item) => (item[field] || "").trim());
  const nonEmpty = dates.filter(Boolean);
  const unique = new Set(nonEmpty);
  if (nonEmpty.length === items.length && unique.size === 1) {
    return nonEmpty[0];
  }
  return items
    .map((item, index) => `${dates[index] || "-"}(${getQtyLabel(item)})`)
    .join(", ");
}

function mergeByPartNo(source: OrderItem[]): DisplayItem[] {
  const groups = new Map<
    string,
    {
      key: string;
      base: OrderItem;
      items: OrderItem[];
      totalQty: number;
      totalAmount: number;
      totalPriceAmount: number;
    }
  >();

  for (const item of source) {
    const partNo = item.零件号?.trim();
    const key = partNo || item.id;
    const qty = parseAmount(item.数量);
    const price = parseAmount(item.价格);
    const amount = parseAmount(item.金额);

    let group = groups.get(key);
    if (!group) {
      group = {
        key,
        base: { ...item },
        items: [],
        totalQty: 0,
        totalAmount: 0,
        totalPriceAmount: 0,
      };
      groups.set(key, group);
    }

    group.items.push(item);

    group.totalQty += qty;
    const computedAmount = amount || qty * price;
    group.totalAmount += computedAmount;
    group.totalPriceAmount += qty * price;
  }

  return Array.from(groups.values()).map((group) => {
    if (group.items.length <= 1) {
      return {
        ...group.base,
        _mergeCount: 1,
      };
    }

    const mergedPrice =
      group.totalQty > 0 ? group.totalPriceAmount / group.totalQty : 0;
    return {
      ...group.base,
      id: group.key,
      数量: formatNumber(group.totalQty, 2),
      价格: formatNumber(mergedPrice, 6),
      金额: formatNumber(group.totalAmount, 4),
      计划交货日期: formatMergedDates(group.items, "计划交货日期"),
      订单交期: formatMergedDates(group.items, "订单交期"),
      _mergeCount: group.items.length,
    };
  });
}

export const usePdfStore = defineStore("pdf", () => {
  // State
  const items = ref<OrderItem[]>([]);
  const pdfInfo = ref<PdfInfo | null>(null);
  const isLoading = ref(false);
  const filePath = ref("");
  const mergeSamePartNo = ref(false);

  // Getters
  const hasData = computed(() => items.value.length > 0);
  const mergedItems = computed(() => mergeByPartNo(items.value));
  const displayItems = computed(() =>
    mergeSamePartNo.value ? mergedItems.value : items.value
  );
  const exportItems = computed(() => displayItems.value);
  const totalAmount = computed(() => {
    return items.value.reduce((sum, item) => {
      const amount = parseAmount(item.金额);
      return sum + amount;
    }, 0);
  });
  const totalQuantity = computed(() => {
    return items.value.reduce((sum, item) => {
      const qty = parseAmount(item.数量);
      return sum + qty;
    }, 0);
  });

  // Actions
  function setItems(newItems: OrderItem[]) {
    items.value = newItems;
  }

  function setPdfInfo(info: PdfInfo) {
    pdfInfo.value = info;
  }

  function updateItem(index: number, field: keyof OrderItem, value: string) {
    if (items.value[index]) {
      items.value[index][field] = value;
    }
  }

  function deleteItem(index: number) {
    items.value.splice(index, 1);
  }

  function addItem(item?: Partial<OrderItem>) {
    const newItem: OrderItem = {
      id: Date.now().toString(),
      日期: item?.日期 || new Date().toISOString().split("T")[0],
      客户名: item?.客户名 || pdfInfo.value?.customerName || "",
      订单号: item?.订单号 || pdfInfo.value?.orderNo || "",
      零件号: item?.零件号 || "",
      零件描述: item?.零件描述 || "",
      数量: item?.数量 || "0",
      价格: item?.价格 || "0",
      金额: item?.金额 || "0",
      计划交货日期: item?.计划交货日期 || "",
      订单交期: item?.订单交期 || "",
    };
    items.value.push(newItem);
  }

  function clearData() {
    items.value = [];
    pdfInfo.value = null;
    filePath.value = "";
  }

  function setFilePath(path: string) {
    filePath.value = path;
  }

  function setLoading(loading: boolean) {
    isLoading.value = loading;
  }

  function setMergeSamePartNo(merge: boolean) {
    mergeSamePartNo.value = merge;
  }

  return {
    // State
    items,
    pdfInfo,
    isLoading,
    filePath,
    mergeSamePartNo,
    // Getters
    hasData,
    displayItems,
    exportItems,
    totalAmount,
    totalQuantity,
    // Actions
    setItems,
    setPdfInfo,
    updateItem,
    deleteItem,
    addItem,
    clearData,
    setFilePath,
    setLoading,
    setMergeSamePartNo,
  };
});
