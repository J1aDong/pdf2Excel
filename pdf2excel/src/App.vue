<template>
  <div class="min-h-screen bg-background flex flex-col">
    <!-- Header -->
    <header class="border-b bg-card px-6 py-4">
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-3">
          <div class="w-8 h-8 rounded-lg bg-primary flex items-center justify-center">
            <svg class="w-5 h-5 text-primary-foreground" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/><path d="M10 9H8"/><path d="M16 13H8"/><path d="M16 17H8"/></svg>
          </div>
          <div>
            <h1 class="text-xl font-semibold">PDF 转 Excel</h1>
            <p class="text-xs text-muted-foreground">采购订单智能转换工具</p>
          </div>
        </div>
        <div class="flex items-center gap-2">
          <Button variant="outline" size="sm" @click="openFile" :loading="isLoading">
            <svg class="w-4 h-4 mr-2" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>
            导入 PDF
          </Button>
          <Button size="sm" @click="exportExcel" :disabled="!hasData" :loading="isExporting">
            <svg class="w-4 h-4 mr-2" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
            导出 Excel
          </Button>
        </div>
      </div>
    </header>

    <!-- Main Content -->
    <main class="flex-1 p-6 overflow-hidden flex flex-col">
      <!-- Info Cards -->
      <div v-if="pdfInfo" class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
        <Card>
          <CardHeader class="pb-2">
            <CardDescription>订单号</CardDescription>
            <CardTitle class="text-lg">{{ pdfInfo.orderNo || "-" }}</CardTitle>
          </CardHeader>
        </Card>
        <Card>
          <CardHeader class="pb-2">
            <CardDescription>客户名称</CardDescription>
            <CardTitle class="text-lg truncate">{{ pdfInfo.customerName || "-" }}</CardTitle>
          </CardHeader>
        </Card>
        <Card>
          <CardHeader class="pb-2">
            <CardDescription>供应商</CardDescription>
            <CardTitle class="text-lg truncate">{{ pdfInfo.supplierName || "-" }}</CardTitle>
          </CardHeader>
        </Card>
      </div>

      <!-- Error Alert -->
      <Alert v-if="errorMessage" variant="destructive" class="mb-4">
        <svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
        <AlertTitle>错误</AlertTitle>
        <AlertDescription>{{ errorMessage }}</AlertDescription>
      </Alert>

      <!-- Empty State -->
      <div v-if="!hasData && !isLoading" class="flex-1 flex flex-col items-center justify-center text-center p-8">
        <div class="w-24 h-24 rounded-full bg-muted flex items-center justify-center mb-4">
          <svg class="w-12 h-12 text-muted-foreground" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/><path d="M12 12v6"/><path d="m15 15-3-3-3 3"/></svg>
        </div>
        <h3 class="text-lg font-semibold mb-2">导入 PDF 文件</h3>
        <p class="text-muted-foreground max-w-sm mb-6">
          支持采购订单 PDF 文件，自动提取表格数据并转换为可编辑的 Excel 格式
        </p>
        <Button @click="openFile" :loading="isLoading">
          <svg class="w-4 h-4 mr-2" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>
          选择文件
        </Button>
      </div>

      <!-- Data Table -->
      <div v-else-if="hasData" class="flex-1 overflow-hidden flex flex-col">
        <DataTable />
      </div>
    </main>

    <!-- Footer -->
    <footer class="border-t bg-card px-6 py-3">
      <div class="flex items-center justify-between text-xs text-muted-foreground">
        <span>PDF2Excel v1.0</span>
        <span>支持 Windows & macOS</span>
      </div>
    </footer>
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";
import { storeToRefs } from "pinia";
import { open, save } from "@tauri-apps/plugin-dialog";
import { invoke } from "@tauri-apps/api/core";
import { usePdfStore } from "@/stores/pdfStore";
import Button from "./components/ui/Button.vue";
import Card from "./components/ui/Card.vue";
import CardHeader from "./components/ui/CardHeader.vue";
import CardTitle from "./components/ui/CardTitle.vue";
import CardDescription from "./components/ui/CardDescription.vue";
import Alert from "./components/ui/Alert.vue";
import AlertTitle from "./components/ui/AlertTitle.vue";
import AlertDescription from "./components/ui/AlertDescription.vue";
import DataTable from "./components/DataTable.vue";

const store = usePdfStore();
const { hasData, pdfInfo, isLoading, exportItems } = storeToRefs(store);

const errorMessage = ref("");
const isExporting = ref(false);

async function openFile() {
  errorMessage.value = "";
  
  try {
    const selected = await open({
      multiple: false,
      filters: [
        { name: "PDF 文件", extensions: ["pdf"] },
        { name: "所有文件", extensions: ["*"] },
      ],
    });

    if (selected && typeof selected === "string") {
      store.setFilePath(selected);
      store.setLoading(true);
      
      try {
        // Call Rust backend to parse PDF
        const result: { items: any[]; info: any } = await invoke("parse_pdf", { path: selected });
        store.setItems(result.items);
        store.setPdfInfo(result.info);
      } catch (err: any) {
        errorMessage.value = err.toString() || "解析 PDF 失败";
      } finally {
        store.setLoading(false);
      }
    }
  } catch (err: any) {
    errorMessage.value = err.toString() || "选择文件失败";
  }
}

async function exportExcel() {
  if (!hasData.value) return;
  
  errorMessage.value = "";
  isExporting.value = true;
  
  try {
    const savePath = await save({
      filters: [
        { name: "Excel 文件", extensions: ["xlsx"] },
      ],
      defaultPath: `采购订单_${pdfInfo.value?.orderNo || "导出"}.xlsx`,
    });

    if (savePath) {
      await invoke("export_excel", {
        path: savePath,
        data: exportItems.value,
        info: pdfInfo.value,
      });
      
      alert("导出成功！");
    }
  } catch (err: any) {
    errorMessage.value = err.toString() || "导出失败";
  } finally {
    isExporting.value = false;
  }
}
</script>
