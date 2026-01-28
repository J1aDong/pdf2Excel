<template>
  <div class="w-full">
    <!-- Toolbar -->
    <div class="flex items-center justify-between mb-4 gap-4 flex-wrap">
      <div class="flex items-center gap-2">
        <Button variant="outline" size="sm" @click="onAddRow" :disabled="mergeSamePartNo">
          <svg class="w-4 h-4 mr-1" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14"/><path d="M12 5v14"/></svg>
          添加行
        </Button>
        <Button variant="outline" size="sm" @click="onClear" class="text-destructive hover:text-destructive">
          <svg class="w-4 h-4 mr-1" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>
          清空
        </Button>
        <label class="flex items-center gap-2 text-sm text-muted-foreground">
          <input
            type="checkbox"
            class="h-4 w-4 rounded border-input text-primary focus:ring-ring"
            v-model="mergeSamePartNo"
          />
          合并同料号
        </label>
      </div>
      <div class="flex items-center gap-4 text-sm text-muted-foreground">
        <span>共 {{ displayItems.length }} 行</span>
        <span>总数量: {{ formatNumber(totalQuantity) }}</span>
        <span>总金额: ¥{{ formatNumber(totalAmount) }}</span>
      </div>
    </div>

    <!-- Table -->
    <div class="rounded-md border overflow-hidden">
      <div class="overflow-x-auto max-h-[60vh]">
        <table class="w-full text-sm">
          <thead class="bg-muted sticky top-0 z-10">
            <tr>
              <th class="h-10 px-2 text-left align-middle font-medium text-muted-foreground w-10">#</th>
              <th class="h-10 px-2 text-left align-middle font-medium text-muted-foreground min-w-[100px]">日期</th>
              <th class="h-10 px-2 text-left align-middle font-medium text-muted-foreground min-w-[120px]">客户名</th>
              <th class="h-10 px-2 text-left align-middle font-medium text-muted-foreground min-w-[120px]">订单号</th>
              <th class="h-10 px-2 text-left align-middle font-medium text-muted-foreground min-w-[150px]">零件号</th>
              <th class="h-10 px-2 text-left align-middle font-medium text-muted-foreground min-w-[200px]">零件描述/规格</th>
              <th class="h-10 px-2 text-left align-middle font-medium text-muted-foreground min-w-[80px]">数量</th>
              <th class="h-10 px-2 text-left align-middle font-medium text-muted-foreground min-w-[100px]">价格(未税)</th>
              <th class="h-10 px-2 text-left align-middle font-medium text-muted-foreground min-w-[100px]">金额(未税)</th>
              <th class="h-10 px-2 text-left align-middle font-medium text-muted-foreground min-w-[120px]">计划交货日期</th>
              <th class="h-10 px-2 text-left align-middle font-medium text-muted-foreground min-w-[120px]">订单交期</th>
              <th class="h-10 px-2 text-center align-middle font-medium text-muted-foreground w-16">操作</th>
            </tr>
          </thead>
          <TransitionGroup name="merge" tag="tbody">
            <tr
              v-for="(item, index) in displayItems"
              :key="item.id"
              :class="[
                'border-b transition-colors hover:bg-muted/50',
                mergeSamePartNo && item._mergeCount && item._mergeCount > 1
                  ? 'merge-highlight'
                  : '',
              ]"
            >
              <td class="p-2 align-middle text-muted-foreground">{{ index + 1 }}</td>
              <td class="p-1 align-middle">
                <Input v-model="item.日期" class="h-8 min-w-[100px]" placeholder="YYYY-MM-DD" :readonly="mergeSamePartNo" />
              </td>
              <td class="p-1 align-middle">
                <Input v-model="item.客户名" class="h-8 min-w-[120px]" :readonly="mergeSamePartNo" />
              </td>
              <td class="p-1 align-middle">
                <Input v-model="item.订单号" class="h-8 min-w-[120px]" :readonly="mergeSamePartNo" />
              </td>
              <td class="p-1 align-middle">
                <Input v-model="item.零件号" class="h-8 min-w-[150px]" :readonly="mergeSamePartNo" />
              </td>
              <td class="p-1 align-middle">
                <Input v-model="item.零件描述" class="h-8 min-w-[200px]" :readonly="mergeSamePartNo" />
              </td>
              <td class="p-1 align-middle">
                <Input v-model="item.数量" class="h-8 min-w-[80px]" @blur="calculateAmount(index)" :readonly="mergeSamePartNo" />
              </td>
              <td class="p-1 align-middle">
                <Input v-model="item.价格" class="h-8 min-w-[100px]" @blur="calculateAmount(index)" :readonly="mergeSamePartNo" />
              </td>
              <td class="p-1 align-middle">
                <Input v-model="item.金额" class="h-8 min-w-[100px]" readonly />
              </td>
              <td class="p-1 align-middle">
                <Input v-model="item.计划交货日期" class="h-8 min-w-[120px]" placeholder="YYYYMMDD" :readonly="mergeSamePartNo" />
              </td>
              <td class="p-1 align-middle">
                <Input v-model="item.订单交期" class="h-8 min-w-[120px]" placeholder="YYYYMMDD" :readonly="mergeSamePartNo" />
              </td>
              <td class="p-1 align-middle text-center">
                <Button variant="ghost" size="icon" class="h-8 w-8 text-destructive" :disabled="mergeSamePartNo" @click="onDeleteRow(index)">
                  <svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>
                </Button>
              </td>
            </tr>
            <tr v-if="displayItems.length === 0" key="empty">
              <td colspan="12" class="h-32 text-center text-muted-foreground">
                暂无数据，请导入 PDF 文件
              </td>
            </tr>
          </TransitionGroup>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { storeToRefs } from "pinia";
import { usePdfStore } from "@/stores/pdfStore";
import Button from "./ui/Button.vue";
import Input from "./ui/Input.vue";

const store = usePdfStore();
const { items, displayItems, totalAmount, totalQuantity, mergeSamePartNo } = storeToRefs(store);

function formatNumber(num: number): string {
  return num.toLocaleString("zh-CN", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function calculateAmount(index: number) {
  if (mergeSamePartNo.value) return;
  const item = items.value[index];
  if (item) {
    const qty = parseFloat(item.数量.replace(/,/g, "")) || 0;
    const price = parseFloat(item.价格.replace(/,/g, "")) || 0;
    const amount = qty * price;
    item.金额 = amount.toFixed(2);
  }
}

function onAddRow() {
  store.addItem();
}

function onDeleteRow(index: number) {
  if (confirm("确定要删除这一行吗？")) {
    store.deleteItem(index);
  }
}

function onClear() {
  if (confirm("确定要清空所有数据吗？")) {
    store.clearData();
  }
}
</script>

<style scoped>
.merge-enter-active,
.merge-leave-active {
  transition: all 220ms ease;
}

.merge-enter-from,
.merge-leave-to {
  opacity: 0;
  transform: translateY(6px);
}

.merge-move {
  transition: transform 220ms ease;
}

.merge-highlight td {
  background-color: rgba(59, 130, 246, 0.06);
  animation: mergePulse 700ms ease-out;
}

@keyframes mergePulse {
  0% {
    background-color: rgba(59, 130, 246, 0.18);
  }
  100% {
    background-color: rgba(59, 130, 246, 0.06);
  }
}
</style>
