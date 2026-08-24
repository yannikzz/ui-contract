<script setup lang="ts">
import Region from '../ui/Region.vue'
</script>

<template>
  <Region id="app-shell">
    <Region id="title-row">标题</Region>
    <Region id="body">
      <Region id="nav">导航</Region>
      <Region id="stage">
        <Region id="main">
          <Region id="main.content">内容</Region>
          <Region id="main.actions">动作</Region>
        </Region>
      </Region>
    </Region>
  </Region>
</template>
