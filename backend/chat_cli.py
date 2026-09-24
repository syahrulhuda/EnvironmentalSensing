import sys
from app.services.ai_service import ask_esi

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

def main():
    print("=" * 65)
    print("🤖 ESI - Environmental Sensing Intelligence (ESS POLTEKOM)")
    print("Ketik pertanyaan Anda (misal: 'Bagaimana kondisi bengkel jam 12 tadi?')")
    print("Ketik 'exit' atau 'keluar' untuk mengakhiri percakapan.")
    print("=" * 65)

    while True:
        try:
            user_input = input("\n👤 Anda: ").strip()
            if not user_input:
                continue
            if user_input.lower() in ["exit", "keluar", "quit", "q"]:
                print("\n👋 Sampai jumpa! Tetap utamakan Safety First di bengkel.")
                break

            print("\n⏳ ESI sedang menganalisis data sensor ESS...")
            res = ask_esi(user_input)
            print(f"\n🤖 ESI:\n{res['reply']}\n")
            print("-" * 65)
        except (KeyboardInterrupt, EOFError):
            print("\n👋 Percakapan diakhiri.")
            break

if __name__ == "__main__":
    main()
