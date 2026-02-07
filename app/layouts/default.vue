<template>
  <div class="app">
    <main class="container">
      <slot />
    </main>
    <footer class="footer">
      <p>serverless-ssr-pattern | Multi-region Serverless Architecture | {{ new Date().getFullYear() }}</p>
    </footer>
  </div>
</template>

<style scoped>
.app {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

main {
  flex: 1;
}
</style>
