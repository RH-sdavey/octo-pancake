import discord
import os
import random

from discord.utils import find


from keep_alive import keep_alive
from data.responses import quotes

client = discord.Client()

@client.event
async def on_ready():
    print("I'm in")
    print(client.user)

@client.event
async def on_message(message):
    # check if client is in mentions
    if not find(lambda m: m.name == client.user.name, message.mentions):
        return
    # check if client is not talking to himself
    if message.author == client.user:
        return


    response = random.choice(quotes)
    await client.send_message(message.channel, response)
    # print(f'{message.author}@{message.channel}: {message.content}')


keep_alive()
token = os.environ.get("DISCORD_BOT_SECRET")
client.run(token)
