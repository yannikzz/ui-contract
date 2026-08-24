<script setup lang="ts">
// 资产层第 3 件：结构容器。运行时标记写在这里一次，且只在这里。
import type { RegionId } from './regions'
defineProps<{ id: RegionId }>()
</script>

<template>
  <div :data-region="id"><slot /></div>
</template>
