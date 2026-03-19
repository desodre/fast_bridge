# Fast Bridge (Frontend)

Este é o frontend do projeto Fast Bridge, desenvolvido em Flutter.

## Como usar o projeto

Por enquanto, para que o projeto funcione, é necessário rodar o servidor backend localmente na sua máquina.

1. **Clone o repositório do backend:**
   Acesse o repositório em [https://github.com/desodre/fast_bridge_backend](https://github.com/desodre/fast_bridge_backend) e faça o clone do projeto.

2. **Rode o backend localmente:**
   Siga as instruções do repositório do backend e inicie o servidor no seu ambiente local utilizando o seguinte comando:
   ```bash
   fastapi dev
   ```

3. **Acesse a interface web:**
   O frontend do projeto já está hospedado e pode ser acessado em: [https://fast-bridge-nine.vercel.app/](https://fast-bridge-nine.vercel.app/).

### Como funciona?
O site hospedado na Vercel fará requisições HTTP diretamente para o seu ambiente local (onde o backend está rodando). Através dessa comunicação, a página web conseguirá capturar e exibir as informações do dispositivo que está fisicamente conectado ao seu computador.
