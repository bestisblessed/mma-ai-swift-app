"""ENHANCING FURTHER:
Advanced Data Visualization:
While markdown has limited capabilities, you can include links to visualizations or integrate images generated from external tools.
Automate Summary Sections:
Implement logic to categorize and summarize different aspects of the data, such as performance metrics, injury history, and matchup predictions.
Integrate with Reporting Tools:
Consider exporting the data in formats compatible with reporting tools (e.g., PDF with advanced formatting, HTML for web-based dashboards).
Feedback Loop:
Implement a feedback mechanism to refine and improve the AI's responses based on the quality and relevance of the output.
"""

import os
from openai import OpenAI
import json
import subprocess

client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))

print("Choose a question or enter your own:")
print("1: Upcoming UFC card/fights overview")
print("2: Max Holloway's recent 5 fights")
print("3: Miami weather forecast")
choice = input("Enter 1-3 or type your question: ").strip()

questions = {
    '1': "Where is the upcoming UFC card/event this weekend and what are all of the fights on it with a short overview of each fight?",
    '2': "Tell me about Max Holloway's most recent 5 fights chronologically",
    '3': "What is the current weather forecast for Miami, Florida?"
}

query = questions.get(choice, choice)  # Use custom input if not 1-3

# query = "Where is the upcoming UFC card/event this weekend and what are all of the fights on it with a short overview of each fight?"
# query = "Tell me about Max Holloway's most recent 5 fights chronologically"
# query = "What is the current weather forecast for Miami, Florida?"
# query = "What is the current weather forecast for Boca Raton, Florida?"
# query = "What is Jon Jones' win-loss record and his most notable victories?"
# query = "How does Khabib Nurmagomedov's grappling statistics compare to Charles Oliveira's, and who has the more effective ground game based on submission rates?"
# query = "Based on their previous performances, what are the key factors that would determine the outcome of a hypothetical fight between Israel Adesanya and Alex Pereira in 2025?"
# query = "How has the average fight duration in UFC heavyweight title bouts changed over the past decade, and what factors might explain this trend?"
# query = "What striking techniques have proven most effective against wrestlers in the UFC lightweight division over the past five years?"
# query = "Which UFC fighters have shown the most significant statistical improvements after changing training camps, and what specific metrics improved?"
# query = "How have recurring knee injuries affected Conor McGregor's movement metrics and strike accuracy compared to his pre-injury performance?"
# query = "What statistical evidence suggests that counter-strikers have an advantage over pressure fighters in championship bouts?"
# query = "Based on performance metrics at similar career stages, is Ilia Topuria on track to surpass Alexander Volkanovski's accomplishments in the featherweight division?"
# query = "How have fighters' performance metrics typically changed when moving up from lightweight to welterweight, and which fighters adapted most successfully?"
# query = "Which statistical indicators have historically been most reliable for predicting upsets in UFC title fights, and how could this information be used to identify betting value in upcoming championship bouts?"
# query = "What are the matchups and predictions for the upcoming UFC card this weekend?"
# query = "What are the top-rated restaurants in Miami that serve authentic Cuban cuisine?"
# query = "What are the most popular tourist attractions in Miami that are within walking distance of South Beach?"
# query = "Show me Conor McGregor's fight history"
# query = "Generate me an insightful visualization of Michael Chandler's statistics and recent fights. Be thorough."
# query = "Who has the most wins by submission in UFC history? Find and tell me the top 5."
# query = "Who has the most wins by submission in UFC history? Find and tell me the top 5. Then generate me an insightful visualzation of something cool and insightful about submissions."
# query = "What's the average age of heavyweight fighters?"


response = client.responses.create(
    model="gpt-4o-mini",
    # model="gpt-4o",
    input=query,
    instructions="""
    You are an expert data analyst and MMA handicapper with extensive knowledge of fighter statistics, fight history, and analytical techniques.

    When analyzing data and providing insights, you should:
    - Utilize the `file_search` tool to locate comprehensive data on fighters, including fight outcomes, methods of victory, opponent profiles, and performance metrics.
    - Use the `web_search` tool to gather the latest information, such as recent fights, training updates, changes in fighter rankings, and news affecting fighter performance.
    - Perform statistical analyses to identify trends and patterns in fighter performance, such as win rates, average fight durations, knockout ratios, and takedown success rates.
    - Compare fighters across multiple metrics to assess strengths, weaknesses, and potential matchups.
    - Provide data-driven predictions and recommendations based on your analyses, including potential outcomes for upcoming fights.
    - Summarize findings with detailed metrics, visualizations (e.g., charts or tables if applicable), and confidence intervals for predictions.
    - Cross-reference multiple data sources to ensure accuracy and reliability of the information.
    - Present your results in a clear, concise, and professional manner suitable for expert-level review.

    After each tool call, add a comprehensive summary of your findings, highlighting key metrics and insights relevant to the fighter's performance and potential future matches.
    """,
    
    tools=[
        {
            "type": "file_search",
            "vector_store_ids": ["vs_67d35d0e2f608191b6398703dc71a931"], # mma-ai-swift-app
            # "vector_store_ids": ["vs_67d1f037ca108191a50d58cd6503afbe"], # responses-api-basic
            # "filters": {
            #     "type": "eq",
            #     "key": "Fighter_ID",
            #     "value": "27944"
            # }
        },
        {
            "type": "web_search_preview",
            "search_context_size": "low",
            # "user_location": {
            #     "type": "approximate",
            #     "city": "Miami"
            # }
        },
    ],
    # stream=True
)

print(response.output)
# for chunk in response:
#     print(chunk.output.content[0].text)

with open("examples/output_{}.md".format(response.id.split('_')[1]), "w", encoding="utf-8") as f:
    title = query.strip().replace("?", "")
    for item in response.output:
        if hasattr(item, 'content'):
            for content in item.content:
                if hasattr(content, 'text'):
                    f.write(content.text + "\n\n")

subprocess.run(["cat", "examples/output_{}.md".format(response.id.split('_')[1])])
