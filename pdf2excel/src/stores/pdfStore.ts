import { defineStore } from "pinia";
import { ref, computed } from "vue";

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

export const usePdfStore = defineStore("pdf", () => {
  // State
  const items = ref<OrderItem[]>([]);
  const pdfInfo = ref<PdfInfo | null>(null);
  const isLoading = ref(false);
  const filePath = ref("");

  // Getters
  const hasData = computed(() => items.value.length > 0);
  const totalAmount = computed(() => {
    return items.value.reduce((sum, item) => {
      const amount = parseFloat(item.金额.replace(/,/g, "")) || 0;
      return sum + amount;
    }, 0);
  });
  const totalQuantity = computed(() => {
    return items.value.reduce((sum, item) => {
      const qty = parseFloat(item.数量.replace(/,/g, "")) || 0;
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

  return {
    // State
    items,
    pdfInfo,
    isLoading,
    filePath,
    // Getters
    hasData,
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
  };
});
