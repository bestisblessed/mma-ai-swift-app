#!/bin/bash

scp -r mma-ai-swift/mma-ai-swift/* Trinity:~/mma-ai-swift-app/mma-ai-swift/mma-ai-swift/
scp -r data/* Trinity:~/mma-ai-swift-app/data/
scp app.py Trinity:~/mma-ai-swift-app
scp mma-ai-swift/mma-ai-swift.xcodeproj/project.pbxproj Trinity:~/mma-ai-swift-app/mma-ai-swift/mma-ai-swift.xcodeproj/
