# How to Contribute

## Your first compile 

1. After you fork the authoritive repository https://github.com/SquareBracketAssociates/PharoLaserGameTutorial and clone it to your local machine, run the script that installs Pharo and Pillar.  
   $ ./download

1. Compile a single chapter, or the whole book.  
   $ ./compile SectionXX/FileXX.pier  
   $ ./compile   

## Recommended setup

1. Add the authoritive repository as a remote named 'sba' and check you can fetch from it.  
   $ git remote add sba https://github.com/SquareBracketAssociates/PharoLaserGameTutorial.git  
   $ git fetch sba

1. Install git completion and branch status prompt.  
   http://www.neverstopbuilding.com/gitpro  

## Workflow with branches

1. Create a topic branch for your work  
   $ git branch MySmallContribution  
   $ git checkout MySmallContribution

1. Edit, compile and commit until you are satisfied with your changes.

1. When your changes are ready to be integrated, its good to squash some commits together for a cleaner history.  It also helps if your commits look like they based off the latest authoritive master. We can do both with an interactive rebase.  
   $ git fetch sba  
   $ git rebase -i sba/master  

1. Push your branch to github the first time.  
   $ git push -u origin MySmallContribution  

   Then from the github web interface select your branch MySmallContribution and issue a 'Pull Request'. If you need to update the pull request based on feedback, just commit to the same branch and push again.  
   $ git push

   If you rebase again, you will need to force the push.  
   $ git push -f origin MySmallContribution

1. While waiting for feedback you can work on another topic branch.   
   $ git checkout AnotherSmallContribution

1. After the pull request is merged, you can delete your local and remote topic branches.   
   $ git branch -d MySmallContribution  
   $ git push origin :MySmallContribution

## Notes

1. We used 'rebase' and 'push -f'  *safely* here with the convention that personal topic branches are "private" (even if they
are visible publically on github) and other people should not merge from these.  You should NOT rebase branches that have been merged into a shared "public" repository.

1. While rebasing, if you lose track of a commit, don't panic.  You can check your local and remote reference logs and reset to one of the commits listed by...  
   $ git reflog show MySmallContribution  
   $ git reflog show remotes/origin/MySmallContribution  
   and then...  
   $ git reset --hard 26ef29a3b # for example

1. Pillar documentation available at https://github.com/pillar-markup/pillar-documentation
