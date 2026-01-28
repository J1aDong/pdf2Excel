import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatDate(dateStr: string): string {
  if (!dateStr || dateStr.length !== 8) return dateStr;
  // Format YYYYMMDD to YYYY-MM-DD
  return `${dateStr.slice(0, 4)}-${dateStr.slice(4, 6)}-${dateStr.slice(6, 8)}`;
}

export function parseAmount(amountStr: string): number {
  if (!amountStr) return 0;
  // Remove commas and convert to number
  return parseFloat(amountStr.replace(/,/g, ""));
}
