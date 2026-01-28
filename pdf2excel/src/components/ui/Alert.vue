<template>
  <div
    :class="cn(
      'relative w-full rounded-lg border px-4 py-3 text-sm [&>svg+div]:translate-y-[-3px] [&>svg]:absolute [&>svg]:left-4 [&>svg]:top-4 [&>svg]:text-foreground [&>svg~*]:pl-7',
      variants[variant],
      $attrs.class
    )"
    v-bind="$attrs"
    role="alert"
  >
    <slot />
  </div>
</template>

<script setup lang="ts">
import { cn } from "@/lib/utils";

defineOptions({
  inheritAttrs: false,
});

interface Props {
  variant?: "default" | "destructive";
}

withDefaults(defineProps<Props>(), {
  variant: "default",
});

const variants = {
  default: "bg-background text-foreground",
  destructive: "border-destructive/50 text-destructive dark:border-destructive [&>svg]:text-destructive",
};
</script>
