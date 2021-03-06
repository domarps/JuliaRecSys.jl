function ALSFactorization(trainingData::SparseMatrixCSC, numberOfFeatures, noOfIterations)
		
	trainingData = filterNonParticipatingUsersAndItems(trainingData)
	#println(trainingData)
	trainingDataTranspose = trainingData'
	(noOfUsers, noOfItems) = size(trainingData)		
	noOfWorkers = nprocs()-1
	# if noOfWorkers == 0
	# 	return
	# end

	# if noOfUsers < noOfWorkers | noOfItems < noOfWorkers
	# 	return
	# end

	println("No of items",noOfItems)
	println("No of workers",noOfWorkers)
	println("No of users",noOfUsers)
	itemMatrix = initializeItemMatrix(trainingData, noOfItems, numberOfFeatures)
	#println(itemMatrix)
	userMatrix = zeros(noOfUsers, numberOfFeatures)
	#println(userMatrix)
	remoteRefOfItemMatrix = distributeMatrixByColumn(itemMatrix, noOfWorkers, noOfItems)	
	remoteRefOfUserMatrix = distributeMatrixByRow(userMatrix, noOfWorkers, noOfUsers)
	remoteRefOfTraningDataByRow = distributeMatrixByRow(trainingData, noOfWorkers, noOfUsers)
	remoteRefOfTraningDataByColumn = distributeMatrixByColumn(trainingData, noOfWorkers, noOfItems)

	for iter = 1: noOfIterations		
		@sync begin
			for worker = 1:noOfWorkers										
				remoteRefOfUserMatrix[worker] = @spawnat worker+1 findU(remoteRefOfTraningDataByRow[worker], remoteRefOfItemMatrix, noOfWorkers, noOfUsers)							
	        end
	        for worker = 1:noOfWorkers		
				remoteRefOfItemMatrix[worker] = @spawnat worker+1 findM(remoteRefOfTraningDataByColumn[worker], remoteRefOfUserMatrix, noOfWorkers, noOfUsers)							
	        end
	 	end       
	end

	#reconstrut the U and M
	ItemMatrix = gatherItemMatrix(remoteRefOfItemMatrix, noOfWorkers)
	UserMatrix = gatherUserMatrix(remoteRefOfUserMatrix, noOfWorkers)
	#UserMatrix * ItemMatrix'
	#Lumberjack.info(logLM,"loadData() method","here")
#	return (UserMatrix, ItemMatrix)
	return ItemMatrix

end
