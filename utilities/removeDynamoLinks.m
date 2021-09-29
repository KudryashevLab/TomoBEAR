function removeDynamoLinks()
linked_files = getDynamoFiles("dynamo");

for i = 1:length(linked_files)
    system("rm " + linked_files(i));
end
end