#!/bin/sh  

function check_submodules_version()
{
	# echo -e "\033[字背景颜色;字体颜色m 字符串 \033[0m"
	color_prefix_red="\033[0;31m"
	color_suffix="\033[0m"

	project_dir=$1
	cd $project_dir
	color_project_dir=$color_prefix_red$project_dir$color_suffix
	echo "cd to repo '$color_project_dir' done"

	echo "check the version of submodules now ..."

	cur_branch=$(git symbolic-ref --short -q HEAD)
	#echo "current branch: $cur_branch"

	temp_has_bad_submodule="$project_dir/.temp_has_bad_submodule"
	rm -f temp_has_bad_submodule
	touch temp_has_bad_submodule

	echo "Here is the all submodules:"

	git submodule status | while read -r line
	do 
		eval `echo $line | awk '{
	    	printf("submodules_head_commit_id=%s; submodule_name=%s", $1, $2)
		}'`
		#echo "$submodule_name: $submodules_head_commit_id" 

		# gradle 执行 'git submodule status' 时，submodule_name 前面带有 '../'，非常奇怪
		# 这个正是用于删除 '../'
		if [[ $submodule_name == ../* ]]
		then
			submodule_name=${submodule_name:3}
		fi

		submodule_path="$project_dir/$submodule_name"
		eval `git ls-tree $cur_branch $submodule_path  | awk '{
	    	printf("submodules_associated_commit_id=%s", $3)
		}'`

		color_submodules_associated_commit_id=$color_prefix_red$submodules_associated_commit_id$color_suffix
		color_submodules_head_commit_id=$color_prefix_red$submodules_head_commit_id$color_suffix

		color_tips=$color_prefix_red"[★]"$color_suffix
		color_right=$color_prefix_red"[✓]"$color_suffix
		color_wrong=$color_prefix_red"[✗]"$color_suffix

		if [ -z "$submodules_associated_commit_id" ]
		then
			echo "$color_tips $submodule_name: a new submodule, and is waiting to be committed"
		else
			if [ $submodules_associated_commit_id = $submodules_head_commit_id ]
			then 
				echo "$color_right $submodule_name: associatedCommitId($color_submodules_associated_commit_id) == headCommitId($color_submodules_head_commit_id)"
			else 
				echo "$color_wrong $submodule_name: associatedCommitId($color_submodules_associated_commit_id) != headCommitId($color_submodules_head_commit_id)"
				echo true > temp_has_bad_submodule
			fi
		fi

	done

	read has_bad_submodule < temp_has_bad_submodule
	rm -f temp_has_bad_submodule

	echo "check the version of submodules done !!!"

	if [ "$has_bad_submodule" = true ]
	then
		fix_cmd="git submodule update --init --recursive"
		color_fix_cmd=$color_prefix_red$fix_cmd$color_suffix
		color_sad=$color_prefix_red"(ToT)"$color_suffix
		echo "$color_sad This main repo has bad submodules, please run this command to fix it: $color_fix_cmd"
		# 1 = false
    	return 1
	else
		color_happy=$color_prefix_red"(^_^)"$color_suffix
		echo "$color_happy This main repo has good submodules, you can have a joy now..."
    	# 0 = true
    	return 0
	fi
}

# test: 假设git_submodule_version_checker.sh脚本放置在主工程git仓库根目录下的一个文件夹，如./script/git_submodule_version_checker.sh
#project_dir=$(cd `dirname $0`; cd ..; pwd)
if [ -n "$1" ]
then
    project_dir=$1
else
	echo "usage: sh PATH_TO/git_submodule_version_checker.sh PATH_TO_MAIN_GIT_REPO "
	exit 1
fi

# 通过重定向，使得不打印检测的日志
#check_submodules_version $project_dir >/dev/null 2>&1

check_submodules_version $project_dir


# demo：主工程根目录下，调用脚本检测子模块的版本
# root_dir=$(pwd); sh script/git_submodule_version_checker.sh $root_dir; if [ $? != 0 ]; then echo "error: This main repo has bad submodules, please run this command to fix it: git submodule update --init --recursive" >&2 ; fi


