"""
Interactive CLI Client for ESI AI Agent
Laboratorium & Bengkel Politeknik Kota Malang (POLTEKOM)
"""

import sys
import os
from dotenv import load_dotenv

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding='utf-8')

load_dotenv()
from ai_agent import process_chat_message

def main():
    print("=" * 65)
    print("🤖 ESI - Environmental Safety Intelligence (K3 POLTEKOM)")
    print("Ketik pertanyaan Anda (misal: 'Bagaimana kondisi bengkel saat ini?')")
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

            print("\n⏳ ESI sedang menganalisis data sensor...")
            res = process_chat_message(user_input)
            print(f"\n🤖 ESI:\n{res['reply']}\n")
            print("-" * 65)
        except (KeyboardInterrupt, EOFError):
            print("\n👋 Percakapan diakhiri.")
            break

if __name__ == "__main__":
    main()
