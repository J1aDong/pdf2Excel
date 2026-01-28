<template>
  <div :class="cn('text-sm [&_p]:leading-relaxed', $attrs.class)" v-bind="$attrs">
    <slot />
  </div>
</template>

<script setup lang="ts">
import { cn } from "@/lib/utils";

defineOptions({
  inheritAttrs: false,
});
</script>
