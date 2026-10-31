DEBUG ?= 0
FINALPACKAGE ?= 1
ARCHS = arm64 arm64e

# Rootless / RootHide 均以 iOS 15 为最低部署目标，SDK 与本机 Theos 一致。
TARGET = iphone:clang:16.5:15.0
