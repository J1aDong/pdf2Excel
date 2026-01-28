<template>
  <div :class="cn(variants[variant], 'inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2', $attrs.class)" v-bind="$attrs">
    <slot />
  </div>
</template>

<script setup lang="ts">
import { cn } from "@/lib/utils";

defineOptions({
  inheritAttrs: false,
});

interface Props {
  variant?: "default" | "secondary" | "destructive" | "outline";
}

withDefaults(defineProps<Props>(), {
  variant: "default",
});

const variants = {
  default: "border-transparent bg-primary text-primary-foreground hover:bg-primary/80",
  secondary: "border-transparent bg-secondary text-secondary-foreground hover:bg-secondary/80",
  destructive: "border-transparent bg-destructive text-destructive-foreground hover:bg-destructive/80",
  outline: "text-foreground",
};
</script>
